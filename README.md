# predict_rating

OUTLINE:

**ABSTRACT:**\
    In the movie industry, the ability to predict whether a movie is going to be popular and well-received is very important.
    This paper discusses and presents some methods of calculating a reviewer's rating of a movie, based on a database.

**INTRODUCTION:**\
    The database used in this paper will be from Grouplens's movielens dataset. In more details, it will be specifically the 3 datasets:\
        -  *MovieLens 25M Dataset*\
        -  MovieLens Small Dataset\
        -  *MovieLens Full Dataset*\
    So far, only the Small Dataset has been tested (May 23, Noon)
    In each dataset, only 4 files are considered so far: \
        1. ratings.csv\
        2. movies.csv\
        3. links.csv\
        4. tags.csv\
    With regards to usable information, only 2 files: ratings.csv and movies.csv are necessary. 

**PROBLEM:**\
    One would need to be able to predict a reviewer's rating as precise as possible. 

**SOLUTION:**\
    In order to solve this problem, the dataset must be used to build clusters of similar movies in a way that if a new viewer comes along, then they can be sorted into similar cluster either based on their movies.\
    After splitting the dataset, into 80% for training and cluster building and 20% for testing, the training dataset can be used to build a similar relationship between the movies. \
    This can be calculated by their genre simillarity (Specifically can be calculated by Jaccard's Similarity) in combination with a similar rating of a viewer. The principle behind this idea is that if a viewer watches movies that are similar to each other, then their rating must also be similar. \
    To combat situation where a similar movie might have been done terribly, the cosine similarity of the rating required to form a similar relationship between the movies must also be higher than a threshold.

**CORRECTNESS PROOF:**\

**EXAMPLES:**\

**DRAWBACK:**\

**CONCLUSION:**\

**REFERENCES:**\