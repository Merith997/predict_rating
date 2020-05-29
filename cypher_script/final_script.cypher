movielens

MATCH (u) DETACH DELETE u;

------------------------------------------------------------------------------------------

// Create node constraints
//
CREATE CONSTRAINT movie_id ON (m:Movie) ASSERT m.id IS UNIQUE;
CREATE CONSTRAINT user_id ON (u:User) ASSERT u.id IS UNIQUE;
CREATE CONSTRAINT test_user_id ON (u:Test) ASSERT u.id IS UNIQUE;
CREATE CONSTRAINT train_user_id ON (u:Train) ASSERT u.id IS UNIQUE;

------------------------------------------------------------------------------------------

// Import movie data
//
LOAD CSV WITH HEADERS FROM 'file:///ml-latest-small/movies.csv' AS map
CREATE (m:Movie {
	id: TOINTEGER(map.movieId),
	title: map.title,
	genres:apoc.text.split(map.genres, '\\|')
});

// Import user & rating data
//
LOAD CSV WITH HEADERS FROM 'file:///ml-latest-small/ratings.csv' AS map
WITH map
	MATCH (m:Movie {id: TOINTEGER(map.movieId)})
	MERGE (u:User {id: TOINTEGER(map.userId)})
    MERGE (u)-[:RATE {rating: TOFLOAT(map.rating), timestamp: TOINTEGER(map.timestamp)}]->(m);

// Normalize user ratings
// TBC: Normalize base on 0-5 scale
//
# MATCH (u:User)-[r:RATE]->(m:Movie)
# WITH u, AVG(r.original_rating) AS u_avg
# 	SET u.avg_rating = u_avg
# WITH AVG(u_avg) AS s_avg
# 	MATCH (u:User)-[r:RATE]->(m:Movie)
# 		SET r.rating = r.original_rating*s_avg/u.avg_rating;

------------------------------------------------------------------------------------------

// Random partition for train & test sets with ratio 80/20
//
MATCH (u:User)-[:RATE]->(m)
WITH DISTINCT(u) AS u, COUNT(m) AS mc
WITH mc, u ORDER BY mc DESC
WITH COLLECT(u) AS uc
WITH apoc.coll.partition(uc, SIZE(uc)/60) AS partitions
WITH REDUCE(l=[], p IN partitions | l + apoc.coll.randomItems(p, SIZE(p)/5)) AS uc
WITH uc UNWIND uc AS u
WITH u
    SET u:Test;

MATCH (u:User)
	WHERE NOT('Test' IN LABELS(u))
		SET u:Train;

# MATCH (u:User) REMOVE u:Test, u:Train

------------------------------------------------------------------------------------------

// Cutoff 80/20 for user-to-user
//
MATCH (n:Train)-[:RATE*2]-(o:Train)
	WHERE n.id < o.id
WITH DISTINCT([n.id, o.id]) AS p, COUNT(*) AS rc
WITH DISTINCT(rc) AS rc, COUNT(*) AS pc ORDER BY rc DESC
WITH COLLECT([rc, pc]) AS cc, SUM(pc) AS s
RETURN
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>1*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_20_percent,
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>4*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_80_percent;

// Cutoff 80/20 for movie-to-user
//
MATCH (m:Movie)<-[r1:RATE]-(u:Train)
WITH DISTINCT(m.id) AS m, COUNT(*) AS uc
WITH DISTINCT(uc) AS uc, COUNT(*) AS mc ORDER BY uc DESC
WITH COLLECT([uc, mc]) AS cc, SUM(mc) AS s
RETURN
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>1*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_20_percent,
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>4*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_80_percent;

// Cutoff 80/20 for movie-to-movie
//
MATCH (n:Movie)-[:RATE*2]-(o:Movie)
	WHERE n.id < o.id
WITH DISTINCT([n.id, o.id]) AS p, COUNT(*) AS rc
WITH DISTINCT(rc) AS rc, COUNT(*) AS pc ORDER BY rc DESC
WITH COLLECT([rc, pc]) AS cc, SUM(pc) AS s
RETURN
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>1*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_20_percent,
	REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>4*s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff_80_percent;

------------------------------------------------------------------------------------------

// Get 10 random test users
//
MATCH (u:Test)
WITH u, SIZE((u)-[:RATE]->()) AS mc ORDER BY rand() LIMIT 10
RETURN COLLECT(u.id) AS uc, COLLECT(mc) AS mc;

// Average rating: predict rating based on the average ratings of trained users
// Display MSE and error ranges
//
WITH [84, 545, 514, 308, 362, 601, 564, 117, 58, 434] AS l
	MATCH (u:Test)-[r1:RATE]->(m:Movie)<-[r2:RATE]-(o:Train)
		WHERE u.id IN l
WITH
	DISTINCT(m) AS m, u, r1.rating AS m_avg, AVG(r2.rating) AS o_avg
WITH u, COLLECT(ABS(m_avg-o_avg)) AS ec, SUM((m_avg-o_avg)^2)/COUNT(m) AS mse
RETURN u.id, REDUCE(l=[0, 0, 0], e IN ec |
	CASE e <= 0.5
    	WHEN TRUE THEN [l[0]+1, l[1], l[2]]
        ELSE CASE e <= 1.0
        	WHEN TRUE THEN [l[0], l[1]+1, l[2]]
            ELSE [l[0], l[1], l[2]+1] END
       END
) AS err, mse AS b_mse ORDER BY u.id;

------------------------------------------------------------------------------------------

// Calculate movie similarity based on:
// - number of users rated both films: at least 22
// - number of common genres of both movies: at least 2
// - cosine similarity score based on user ratings of both movies: at least 0.97
//
CALL apoc.periodic.iterate(
'
	MATCH (m:Movie)
	WITH m ORDER BY m.id
	RETURN m
','
	MATCH (m:Movie)<-[r1:RATE]-(u:Train)-[r2:RATE]->(o:Movie)
		WHERE m.id < o.id
	WITH
		DISTINCT(o) AS o, m,
	  AVG(r1.rating) AS m_avg, AVG(r2.rating) AS o_avg,
		SIZE((m)<-[:RATE]-()) AS m_ratings, SIZE((o)<-[:RATE]-()) AS o_ratings, COUNT(u) AS common_ratings,
		SIZE(apoc.coll.intersection(m.genres, o.genres)) AS common_genres, SIZE(apoc.coll.union(m.genres, o.genres)) AS union_genres,
		SUM(r1.rating*r2.rating)/SQRT(SUM(r1.rating^2)*SUM(r2.rating^2)) AS rating_cosine
	WITH
		m, o, m_avg, o_avg, common_ratings, common_genres, rating_cosine,
		1.0*common_ratings/(m_ratings+o_ratings-common_ratings) AS rating_jaccard,
		1.0*common_genres/union_genres AS genre_jaccard
		WHERE common_ratings >= 22 AND common_genres > 1 AND rating_cosine >= 0.97
		MERGE (m)-[:SIMILAR {
			rating: [m_avg, o_avg],
			common_genres: common_genres,
			genre_jaccard: genre_jaccard,
			common_ratings: common_ratings,
			rating_jaccard: rating_jaccard,
			rating_cosine: rating_cosine
		}]-(o)
',
	{batchSize: 1}
);

// MATCH ()-[r:SIMILAR]-() DETACH DELETE r;

// Predict rating based on the average ratings of trained users, and ratings of similar movies
// Display MSE and error ranges
//
WITH [84, 545, 514, 308, 362, 601, 564, 117, 58, 434] AS l
	MATCH (u:Test)
		WHERE u.id IN l
WITH u
	MATCH (u)-[r1:RATE]->(m:Movie)-[sr:SIMILAR]-(o:Movie)<-[r2:RATE]-(:Train)
WITH
	DISTINCT(m) AS m, u, r1.rating AS u_rating,
	AVG(r2.rating) AS a1_rating,
	AVG((sr.rating[0]+sr.rating[1])/2) AS a2_rating
WITH
	u, COLLECT(ABS(u_rating-a1_rating)) AS ec1, COLLECT(ABS(u_rating-a2_rating)) AS ec2,
	SUM((u_rating-a1_rating)^2)/COUNT(m) AS mse1, SUM((u_rating-a2_rating)^2)/COUNT(m) AS mse2
RETURN
	u.id,
	REDUCE(l=[0, 0, 0], e IN ec1 |
		CASE e <= 0.5
    	WHEN TRUE THEN [l[0]+1, l[1], l[2]]
        ELSE CASE e <= 1.0
        	WHEN TRUE THEN [l[0], l[1]+1, l[2]]
          ELSE [l[0], l[1], l[2]+1] END
      END
	) AS err1, mse1 AS n_mse1,
	REDUCE(l=[0, 0, 0], e IN ec2 |
		CASE e <= 0.5
    	WHEN TRUE THEN [l[0]+1, l[1], l[2]]
      ELSE CASE e <= 1.0
      	WHEN TRUE THEN [l[0], l[1]+1, l[2]]
          ELSE [l[0], l[1], l[2]+1] END
      END
	) AS err2, mse2 AS n_mse2 ORDER BY u.id;

------------------------------------------------------------------------------------------

// Calculate user similarity based on:
// - number of movies rated by both users: at least 4
// - jaccard similarity score based on the numbers of see movies: at least 0.2
//
CALL apoc.periodic.iterate(
'
	MATCH (u:Test)
	RETURN u
','
	MATCH (u)-[:RATE]->(m:Movie)<-[:RATE]-(o:Train)
	WITH
		DISTINCT(o) AS o, u,
		SIZE((u)-[:RATE]->()) AS u_ratings, SIZE((o)-[:RATE]->()) AS o_ratings, COUNT(m) AS common_ratings
	WITH
		u, o, common_ratings,
		1.0*common_ratings/(u_ratings+o_ratings-common_ratings) AS rating_jaccard
		WHERE common_ratings >= 4 AND rating_jaccard >= 0.2
	WITH
		u, o, common_ratings, rating_jaccard
		ORDER BY rating_jaccard DESC, common_ratings DESC LIMIT 20
	WITH
		u, o, common_ratings, rating_jaccard
		MERGE (u)-[:NEAREST {
			common_ratings: common_ratings,
			rating_jaccard: rating_jaccard
		}]-(o)
',
	{batchSize: 1}
)

// MATCH (u:Test)-[:NEAREST]-()
// WITH DISTINCT(u) AS u, COUNT(*) AS nc
// WITH nc, COUNT(u) AS uc ORDER BY nc DESC
// RETURN SUM(uc);

// MATCH ()-[r:NEAREST]-() DETACH DELETE r;

WITH [84, 545, 514, 308, 362, 601, 564, 117, 58, 434] AS l
	MATCH (u:Test)
		WHERE u.id IN l
WITH u
	MATCH (u)-[:NEAREST]-(o:Train)
WITH u, o
	MATCH (u)-[r1:RATE]->(m:Movie)<-[r2:RATE]-(o)
WITH DISTINCT(m) AS m, u, r1.rating AS u_rating, AVG(r2.rating) AS a_rating
WITH u, COLLECT(ABS(u_rating-a_rating)) AS ec, SUM((u_rating-a_rating)^2)/COUNT(m) AS mse
RETURN u.id, REDUCE(l=[0, 0, 0], e IN ec |
	CASE e <= 0.5
    	WHEN TRUE THEN [l[0]+1, l[1], l[2]]
        ELSE CASE e <= 1.0
        	WHEN TRUE THEN [l[0], l[1]+1, l[2]]
            ELSE [l[0], l[1], l[2]+1] END
       END
) AS err, mse AS n_mse ORDER BY u.id;


------------------------------------------------------------------------------------------

// Calculate user similarity based on:
// - number of movies rated by both users: at least 4
// - cosine similarity score of both users based seen movie genres: at least 0.9
//
CALL apoc.periodic.iterate(
'
	MATCH (u:Test)-[:RATE]->(m:Movie)
	WITH u, COUNT(m) AS um, COLLECT([g IN m.genres | [g, 1.0]]) AS gl
	WITH u, um, REDUCE(l=[], e IN gl | l + e) AS gl
	RETURN u, um, REDUCE(m=apoc.map.fromPairs([]), e IN gl |
		CASE apoc.map.get(m, e[0], NULL, False)
			WHEN NULL THEN apoc.map.setKey(m, e[0], e[1])
			ELSE apoc.map.setKey(m, e[0], apoc.map.get(m, e[0]) + e[1])
			END) AS ugm
','
	WITH u, um, ugm
		MATCH (u)-[:RATE]->(m:Movie)<-[:RATE]->(o:Train)
	WITH DISTINCT(o) AS o, COUNT(m) AS mc, u, um, ugm
	WITH u, um, ugm, mc, o
		MATCH (o)-[:RATE]->(m:Movie)
	WITH u, um, ugm, mc, o, COUNT(m) AS om, COLLECT([g IN m.genres | [g, 1.0]]) AS gl
	WITH u, um, ugm, mc, o, om, REDUCE(l=[], e IN gl | l + e) AS gl
	WITH
		u, um, ugm, mc, o, om,
		REDUCE(m=apoc.map.fromPairs([]), e IN gl |
			CASE apoc.map.get(m, e[0], NULL, False)
				WHEN NULL THEN apoc.map.setKey(m, e[0], e[1])
				ELSE apoc.map.setKey(m, e[0], apoc.map.get(m, e[0]) + e[1])
				END) AS ogm
	WITH
		u, um, mc, o, om,
		REDUCE(l=[0, 0, 0], e IN apoc.map.sortedProperties(ugm) |
			CASE apoc.map.get(ogm, e[0], NULL, False)
				WHEN NULL THEN l ELSE [
					l[0] + apoc.map.get(ugm, e[0])*apoc.map.get(ogm, e[0]),
					l[1]+apoc.map.get(ugm, e[0])^2,
					l[2]+apoc.map.get(ogm, e[0])^2]
				END) AS coeffs
	WITH u, um, o, om, mc AS common_ratings, coeffs[0]/SQRT(coeffs[1]*coeffs[2]) AS genre_cosine
	WITH u, o, common_ratings, genre_cosine
		WHERE common_ratings >= 4 AND genre_cosine >= 0.9
	WITH u, o, common_ratings, genre_cosine ORDER BY genre_cosine DESC, common_ratings DESC LIMIT 20
		MERGE (u)-[:COMMON {
			common_ratings: common_ratings,
			genre_cosine: genre_cosine
		}]-(o)
',
	{batchSize: 1}
)

# MATCH (u:Test)-[:COMMON]-()
# WITH DISTINCT(u) AS u, COUNT(*) AS nc
# WITH nc, COUNT(u) AS uc ORDER BY nc DESC
# RETURN SUM(uc);

# MATCH ()-[r:COMMON]-() DETACH DELETE r;

WITH [84, 545, 514, 308, 362, 601, 564, 117, 58, 434] AS l
	MATCH (u:Test)
		WHERE u.id IN l
WITH u
	MATCH (u)-[:COMMON]-(o:Train)
WITH u, o
	MATCH (u)-[r1:RATE]->(m:Movie)<-[r2:RATE]-(o)
WITH DISTINCT(m) AS m, u, r1.rating AS u_rating, AVG(r2.rating) AS a_rating
WITH u, COLLECT(ABS(u_rating-a_rating)) AS ec, SUM((u_rating-a_rating)^2)/COUNT(m) AS mse
RETURN u.id, REDUCE(l=[0, 0, 0], e IN ec |
	CASE e <= 0.5
    	WHEN TRUE THEN [l[0]+1, l[1], l[2]]
        ELSE CASE e <= 1.0
        	WHEN TRUE THEN [l[0], l[1]+1, l[2]]
            ELSE [l[0], l[1], l[2]+1] END
       END
) AS err, mse AS n_mse ORDER BY u.id;

------------------------------------------------------------------------------------------

// User's genre interests
//
WITH [84] AS l
	MATCH (u:Test)
		WHERE u.id IN l
WITH u
	MATCH (u)-[:RATE]->(m:Movie)
	WITH u, COUNT(m) AS um, COLLECT([g IN m.genres | [g, 1.0]]) AS gl
	WITH u, um, REDUCE(l=[], e IN gl | l + e) AS gl
	RETURN u, um, apoc.map.sortedProperties(REDUCE(m=apoc.map.fromPairs([]), e IN gl |
		CASE apoc.map.get(m, e[0], NULL, False)
			WHEN NULL THEN apoc.map.setKey(m, e[0], e[1])
			ELSE apoc.map.setKey(m, e[0], apoc.map.get(m, e[0]) + e[1])
			END)) AS ugm

// Similar movies seen by the same user
WITH [84] AS l
	MATCH (u:Test)
		WHERE u.id IN l
WITH u
	MATCH (u)-[r1:RATE]->(m:Movie)-[sr:SIMILAR]-(o:Movie)<-[r2:RATE]-(u)
RETURN DISTINCT(m.title) AS title, r1.rating, m.genres, COUNT(sr) AS sc ORDER BY sc DESC
