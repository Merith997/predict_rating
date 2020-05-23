# predict_rating
OUTLINE:
**ABSTRACT:**
    In the movie industry, the ability to predict whether a movie is going to be popular and well-received is very important.
    This paper discusses and presents some methods of calculating a reviewer's rating of a movie, based on a database. 
**INTRODUCTION:**
    The database used in this paper will be from Grouplens's movielens dataset. In more details, it will be specifically the 3 datasets:
        -  *MovieLens 25M Dataset*
        -  MovieLens Small Dataset
        -  *MovieLens Full Dataset*
    So far, only the Small Dataset has been tested (May 23, Noon)
    In each dataset, only 4 files are considered so far: 
        1. ratings.csv
        2. movies.csv
        3. links.csv
        4. tags.csv
    With regards to usable information, only 2 files: ratings.csv and movies.csv are necessary. 
**PROBLEM:**
    One would need to be able to predict a reviewer's rating as precise as possible. 

**SOLUTION:**
    In order to solve this problem, the dataset must be used to build clusters of similar movies in a way that if a new viewer comes along, then they can be sorted into similar cluster either based on their movies.
    