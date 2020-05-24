# predict_rating

OUTLINE:

**ABSTRACT:**  
    In the movie industry, the ability to predict whether a movie is going to be popular and well-received is very important.
    This paper discusses and presents some methods of calculating a reviewer's rating of a movie, based on a database.

**INTRODUCTION:**  
    The database used in this paper will be from Grouplens's movielens dataset. In more details, it will be specifically the 3 datasets:  
        * *MovieLens 25M Dataset*  
        * MovieLens Small Dataset  
        * *MovieLens Full Dataset*  
    So far, only the Small Dataset has been tested (May 23, Noon)
    In each dataset, only 4 files are considered so far:   
        >1. ratings.csv  
        >2. movies.csv  
        >3. links.csv  
        >4. tags.csv  
    With regards to usable information, only 2 files: ratings.csv and movies.csv are necessary. 

**PROBLEM:**  
    In this case, the only data give about the users are the movies that they watch (and the rating, but that is what needed to be predict, so it cannot be used in calculation). How would one use the available data only to predict as close as possible to the true rating. After finding a method, then the next step is to find a way to predict many rating as much as possible.

**SOLUTION:**  
    In order to solve this problem, the prediction must be based on some data. In this particular case, the data is taken from one of the database mentioned above. 
    
    The principle behind the following idea is that if a viewer watches movies that are similar to each other, then each respective rating must also be similar. When predicting a user's movie rating, they can be infer from users who rated similar movies. The closeness in similarity would be used to determine a tolerable margin of error. 

    For each dataset, they are used to build clusters of similar movies in a way that if a new viewer comes along, then they can be sorted into similar cluster either based on their movies rating.  

    The data is randomly splitting the user dataset into an 80/20 ratio. The 80% is for cluster and relationship building, whereas the 20% is for testing. The training data includes all the movies, since a new movie coming in will be requiring a lot more work (This will be further discuss at the Drawback section of the paper).  

    After creating the similar relationship, there is also a need to calculate **how** similar the movies are to each other. At this point, another problem must be considered:  
        A strict person can never give a movie a 5/5 star review, whereas a generous person might never give 1/5 star review. In order to account for both of their rating distribution, all of the ratings must be normalized. This can be done by expanding their rating range (lowest to 0, and highest to 5)  
    
    In addition to using the ratings that a person has given to their respective movies, one can also use the genres of the movies to take into account. This can be calculated by using Jaccard's Similarity. 

    However, being in the same genre is not enough, since within the genre, there are many different movie qualities, that are reflected by the ratings. Therefore, the Cosine Similarity can be used to determine the similarity of the rating.

    Only after calculating the 2 similarities, and they both satisfy a tolerance level, can there be a similar relationship between the movies.

**CORRECTNESS PROOF:**\


**EXAMPLES:**
    Given the datasets mentioned above in the Introduction part as the examples, here are the implementation of the solutions:  
     * MovieLens Small Dataset:  
     * MovieLens 25M Dataset:  
     * MovieLens Full Dataset:  

**DRAWBACK:**\
    Currently the prediction is based solely on the genre category, where as incorporating the gnome would further details the separation. This however, is based on a scoring system, and therefore would need additional scoring between each relevant relationships seen above.

**CONCLUSION:**\

**REFERENCES:**\