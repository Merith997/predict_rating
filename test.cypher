// Drop everything that was there previously
MATCH (u) DETACH DELETE u;
CALL apoc.schema.assert(NULL, NULL);
// Recreate constraints on 4 node types
CREATE CONSTRAINT movie_id ON (m:Movie) ASSERT m.id IS UNIQUE;
CREATE CONSTRAINT user_id ON (u:User) ASSERT u.id IS UNIQUE;
CREATE CONSTRAINT test_user_id ON (u:Test) ASSERT u.id IS UNIQUE;
CREATE CONSTRAINT train_user_id ON (u:Train) ASSERT u.id IS UNIQUE;

// Importing movies.csv
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS map
CREATE (m:Movie {
	id: TOINTEGER(map.movieId), 
	title: map.title, 
	genres:apoc.text.split(map.genres, '\\|')
});

// Import ratings.csv
LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS map
WITH map 
	MATCH (m:Movie {id: TOINTEGER(map.movieId)})
	MERGE (u:User {id: TOINTEGER(map.userId)})
    MERGE (u)-[:RATE {rating: TOFLOAT(map.rating), timestamp: TOINTEGER(map.timestamp)}]->(m);
  
// Split the users into 80/20 with 20 for testing
MATCH (u:User) 
WITH COUNT(u)*8/10 AS c
	MATCH (u:User) 
WITH u.id AS uid, c ORDER BY rand()
WITH COLLECT(uid) AS uc, c
WITH uc[0..c] AS tr, uc[c..] AS ts
WITH tr, ts UNWIND tr AS uid
	MATCH (u:User {id: uid})
		SET u:Train
WITH ts UNWIND ts AS uid		
	MATCH (u:User {id: uid})
		SET u:Test;
		
// Create a cutoff of top 20% close cosine similarities
MATCH (u:Train)-[r1:RATE]->(m)<-[r2:RATE]-(o:Train)
	WHERE u.id < o.id
WITH DISTINCT([u.id, o.id]) AS uo, COUNT(*) AS mc
WITH DISTINCT(mc) AS mc, COUNT(*) AS np ORDER BY mc DESC
WITH COLLECT([mc, np]) AS cc, SUM(np) AS s
RETURN REDUCE(b=[0, 0], e IN cc | CASE 5*b[1]>s WHEN TRUE THEN b ELSE [e[0], b[1]+e[1]] END) AS cutoff;

// Filter and create SIMILAR relationship between movies that has 22 pairs of viewers and similar to >97%:
CALL apoc.periodic.iterate('
	MATCH (m:Movie)
	WITH m ORDER BY m.id
	RETURN m
','
	MATCH (m)<-[r1:RATE]-(u:Train)-[r2:RATE]->(o:Movie)
		WHERE m.id < o.id
	WITH 
		DISTINCT(o) AS o, m, AVG(r1.rating) AS r, COUNT(u) AS uc, 
        SUM(r1.rating*r2.rating)/SQRT(SUM(r1.rating^2)*SUM(r2.rating^2)) AS cosine
	WITH m, o, r, uc, cosine
		WHERE cosine >= 0.97 AND uc >= 22
	WITH m, o, r, cosine
		MERGE (m)-[:SIMILAR {rating: r}]-(o)
', 
	{batchSize: 1}
);

// Perform prediction and then check difference between real rating and mean rating.
MATCH (u:Test)-[r1:RATE]->(m:Movie)<-[r2:RATE]-()
WITH DISTINCT(m) AS m, u, r1.rating-AVG(r2.rating) AS ar
WITH u, SUM(ar^2)/COUNT(m) AS b_mse
WITH u, b_mse
	MATCH (u)-[r1:RATE]->(m:Movie)-[r:SIMILAR]-(o:Movie)
WITH DISTINCT(m) AS m, u, b_mse, r1.rating-AVG(r.rating) AS err
WITH DISTINCT(u) AS u, b_mse, SUM(err^2)/COUNT(m) AS o_mse
RETURN SUM(b_mse), SUM(o_mse), SUM(b_mse)-SUM(o_mse) AS ad ;

// Create projected graph:
CALL gds.graph.create(
    'myGraph',
    {
    		Movie: {
			properties: {
        			id:{
					property: 'id'
				}
			}
		}
    },
    {
		SIMILAR: {
          	properties: {
				rating: {
					property: 'rating'
				}
			}
		}
    }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;

// Run Louvain algorithm and write the new property communityId on data user, based on score property
CALL gds.louvain.write('myGraph', { writeProperty: 'communityId', relationshipWeightProperty: 'rating'})
YIELD communityCount, modularity, modularities
RETURN communityCount, modularity, modularities;

// Export result into prediction.csv
WITH "MATCH (u:Test)-[r1:RATE]->(m:Movie)<-[r2:RATE]-() WITH DISTINCT(m) AS m, u, r1.rating-AVG(r2.rating) AS ar WITH u, SUM(ar^2)/COUNT(m) AS b_mse WITH u, b_mse 	MATCH (u)-[r1:RATE]->(m:Movie)-[r:SIMILAR]-(o:Movie) WITH DISTINCT(m) AS m, u, b_mse, r1.rating-AVG(r.rating) AS err, r1.rating AS true_rating, AVG(r.rating) AS average_rating WITH DISTINCT(u) AS u, b_mse, SUM(err^2)/COUNT(m) AS o_mse, true_rating, average_rating, m RETURN u.id, m, true_rating, average_rating, SUM(b_mse)-SUM(o_mse) AS mse_difference" AS result
CALL apoc.export.csv.query(result, "output_data_all_users.csv", {})
YIELD file, source, format, done
RETURN file, source, format, done;

