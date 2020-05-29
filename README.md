# predict_rating

## **ABSTRACT:**  
In the movie industry, the ability to predict whether a movie is going to be popular and well-received is very important.  
This paper discusses and presents some methods of calculating a reviewer's rating of a movie, based on a database.

## **INTRODUCTION:**  
The database used in this paper will be from Grouplens's movielens dataset. In more details, it will be specifically the MovieLens Small Dataset.  
In the dataset, only 4 files are considered so far:   
    1. ratings.csv  
    2. movies.csv  
    3. links.csv  
    4. tags.csv  
With regards to usable information, only 2 files: ratings.csv and movies.csv are necessary. 

## **PROBLEM:**  
In this case, the only data give about the users are the movies that they watch (and the rating, but that is what needed to be predict, so it cannot be used in calculation). How would one use the available data only to predict as close as possible to the true rating. After finding a method, then the next step is to find a way to predict many rating as much as possible.

## **SOLUTIONS:**  
In order to solve this problem, the prediction must be based on some data. In this particular case, the data is taken from the database mentioned above.  
    
There are 2 methods that will be taken into consideration here. One will be prediction based on similarities between movies, and the other will be based on user similarities.

There is also something to consider prior into discussing the methods. 

For each dataset, they are used to build clusters of similar movies in a way that if a new viewer comes along, then they can be sorted into similar cluster either based on their movies rating.   

The data is randomly splitting the user dataset into an 80/20 ratio. The 80% is for cluster and relationship building, whereas the 20% is for testing. The training data includes all the movies, since a new movie coming in will be requiring a lot more work (This will be further discuss at the Drawback section of the paper).  

After creating the similar relationship, there is also a need to calculate **how** similar the movies are to each other. At this point, another problem must be considered: 
>   A strict person can never give a movie a 5/5 star review, whereas a generous person might never give 1/5 star review.  

In order to account for both of their rating distribution, all of the ratings must be normalized. This can be done by expanding their rating range (lowest to 0, and highest to 5)  

### Method 1 - Movie Similarity:  
The principle behind the idea is that if a viewer watches movies that are similar to each other, then each respective rating must also be similar. When predicting a user's movie rating, they can be infer from users who rated similar movies. The closeness in similarity would be used to determine a tolerable margin of error.  
    
In addition to using the ratings that a person has given to their respective movies, one can also use the genres of the movies to take into account. This can be calculated by using Jaccard's Similarity. 

However, being in the same genre is not enough, since within the genre, there are many different movie qualities, that are reflected by the ratings. Therefore, the Cosine Similarity can be used to determine the similarity of the rating.

Only after calculating the 2 similarities, and they both satisfy a tolerance level, can there be a similar relationship between the movies.

### Method 2 - User Similarity:  

The principle behind the idea is that predicting a viewer's ratings on movies with others who also directly watches those movies. This method however, must also filter out those who have watched the movies, but have different taste in movies. This is achieved via ensuring those viewers not only watches that one movie, but also at least 80% of the list of common movies between them. This limit sets a lower bound on the similarities between all the viewers chosen with the one that is being predicted. 
    
In addition to using the ratings that a person has given to their respective movies, one can also use the genres of the movies to take into account. This can be calculated by using Jaccard's Similarity. 

However, being in the same genre is not enough, since within the genre, there are many different movie qualities, that are reflected by the ratings. Therefore, the Cosine Similarity can be used to determine the similarity of the rating.

Only after calculating the 2 similarities, and they both satisfy a tolerance level, can there be a similar relationship between the movies.


## **CORRECTNESS PROOF:**  
In the calculation, there are also the method of calculating the average rating of 

## **EXAMPLES:**
Given the datasets mentioned above in the Introduction part as the examples, here are the implementation of the solutions:  
    * MovieLens Small Dataset:  
### Step 1: Start the neo4j server  

![Terminal pic](https://github.com/Merith997/predict_rating/blob/master/Images/Initiate%20Neo4j%20to%20start.png)

Since the dataset is not a small one, the community edition is preferred, over the Desktop version.

### Step 2: Setting constraints and importing MovieLens data from GroupLens  

![Constraint](https://github.com/Merith997/predict_rating/blob/master/Images/Create%20constraints.png)
![Normalization](https://github.com/Merith997/predict_rating/blob/master/Images/import%20data%20and%20normalized.png)

In order to calculate faster, and avoid duplicates, the constraints are added above. In the process of importing the ratings from ratings.csv, the User class is also created to link their id and the ratings to respective movies.

### Step 3: After setting the constraints, initiate the relationships per methods  

#### Method 1 - Movie Similarity:  

![Similar_movie](https://github.com/Merith997/predict_rating/blob/master/Images/Similar%20movies.png)

In this case, the similarity depends on 2 factors: the common genres, and user's rating of movies that are similar to those that the test user watched. 

The common genres are calculated by Jaccard Similarity, while the viewer's rating is based on cosine similarity. 

#### Method 2 - User Similarity:  

![User_neighbor](https://github.com/Merith997/predict_rating/blob/master/Images/User%20nearby.png)

In this case, the similarity depends on 1 factor: the common movies and their genres.

The common genres are calculated by Jaccard Similarity, while the viewer's rating is based on cosine similarity. 

### Step 4: Calculate the predictions and compile them to count the number of acceptable predictions  

#### Method 1's output:

![Similar_movie](https://github.com/Merith997/predict_rating/blob/master/Images/Screenshot%20from%202020-05-29%2011-52-18.png)

#### Method 2's output:

![Nearby_User](https://github.com/Merith997/predict_rating/blob/master/Images/Screenshot%20from%202020-05-29%2011-52-00.png)

At this step, the result above can be applied to any amount of users (as the id is inserted into the list, and can be changed anytime using the randomly selected user query). Above, the query returned a result as the user id, the respected number of prediction that perfectly matches with the data, within 0.5 rating, and then the rest. The mse collumn consists of the mean square error, which can be interpreted as the lower it is, the more precise the prediction is.  
The first column is the method where the predicted rating is created from simply taking average of all the ratings of train users who watches that movie. The second column in the method's 1 output is the predicted via the training data and the similar movie algorithm.  
From there, one can see that the algorithm, while not perfectly, but usually produce a better prediction.

### Step 5: Export the data result as needed, in this case, to Gephi  

After using Gephi in conjunction with APOC's own procedure query, the data can be visualized such as above.

## **DRAWBACK:**
Currently the prediction is based solely on the genre category, where as incorporating the gnome would further details the separation. This however, is based on a scoring system, and therefore would need additional scoring between each relevant relationships seen above.

Another drawback mentioned above is the need of having a viewer's movie already in the dataset. However, predicting an already made movie is not as useful as one would want to be able to predict a new movie. Perhaps this is a problem in creating a movie, but not knowing how the public will receive it. However, to take into account new movies, the program will also need to be able to input data, and each time predicting, there would need to be consideration to the old dataset, and how to accomodate newer ones. 

Last but not least, this method of prediction is based on the ratings of the users who are included in the dataset. These are chosen at random, however, they may or may not actually able to represent the true random of the people, nor the outliers, who would rate movies in their own methods. Therefore, this method can only predict but not at a 100% success rate. In the future, this can be improved with more usage of statistics, and perhaps taken into account the type of viewers, which then can consider the biases and improve prediction even more.

## **CONCLUSION:**  

## **REFERENCES:**  
