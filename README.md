# Movie Recommendation

## **ABSTRACT:** 
Predicting a person's rating of a movie is a very hard problem. To predict the rating, there are many ways, based on available data. A way to approach this is through building clusters of similar movies, or people, and then compare a new user to those clusters. The more closer a person is to a cluster, the more their rating can be predicted by the cluster. 

## **INTRODUCTION:** 
In the movie industry, the ability to predict whether a movie is going to be well-received is very important. A way to test this is by showing the movie to a random audience, and then ask them about the rating. This was a very good way, however, this takes time and sometimes, it is not possible to muster a crowd that is random enough to represent the public. Therefore, the problem lays in how can one predict an audience's rating of a movie? How many, and how precise can some one predict a rating?  
In the process of making this project, the dataset used was from Grouplens's MovieLens Small Dataset. The dataset has information about the movie, users and ratings that can be used in this project.
In the dataset, only 4 files are considered so far: 
 1. ratings.csv 
 2. movies.csv 
 3. links.csv 
 4. tags.csv 
With regards to usable information, only 2 files: ratings.csv and movies.csv are necessary. 

## **PROBLEM:** 
In this case, the only data give about the users are the movies that they watch (and the rating, but that is what needed to predict, so it cannot be used in the calculation). How would one use the available data only to predict as closely as possible to the true rating? After finding a method, then the next step is to find a way to predict many ratings as much as possible. 

## **SOLUTIONS:** 
To solve this problem, the prediction must be based on some data. In this particular case, the data is taken from the database mentioned above. 2 methods will be taken into consideration here. One will be a prediction based on similarities between movies, and the other will be based on similarities between users. For each dataset, the rating and other details about the movies and users are used to build groups of similar movies, or users. When predicting a user's rating, they are then compared to the groups to find the most similar group before predict based on the group's data.

The dataset is randomly splitting the user dataset into an 80/20 ratio. 80% is for cluster and relationship building, whereas 20% is for testing. The training data includes all the movies since a new movie coming in will be requiring a lot more work (This will be further discussed in the Drawback section of the paper). After creating a similar relationship, there is also a need to calculate **how** similar the movies are to each other. At this point, another problem must be considered: A strict person can never give a movie a 5/5 star review, whereas a generous person might never give 1/5 star review. In order to account for both of the rating distribution, all of the ratings must be normalized. This can be done by expanding their rating range (lowest to 0, and highest to 5) 

### Method 1 - Movie Similarity: 
The principle behind the idea is that if a user watches movies that are similar to each other, then each respective rating must also be similar. When predicting a user's movie rating, they can be inferred from users who rated similar movies. The closeness in similarity would be used to determine a tolerable margin of error. In addition to using the ratings that a person has given to their respective movies, one can also use the genres of the movies to take into account. This can be calculated using Jaccard's Similarity. However, being in the same genre is not enough, since, within the genre, there are many different movie qualities, that are reflected by the ratings. Therefore, the Cosine Similarity can be used to determine the similarity of the rating. Only after calculating the 2 similarities, and they both satisfy a tolerance level, can there be a similar relationship between the movies.

### Method 2 - User Similarity: 

The principle behind the idea is that predicting a user's ratings on movies with others who also directly watch those movies. This method, however, must also filter out those who have watched the movies but have different tastes in movies. This is achieved via ensuring those users not only watch that one movie but also at least 80% of the list of common movies between them. This limit sets a lower bound on the similarities between all the users chosen with the one that is being predicted. In addition to using the ratings that a person has given to their respective movies, one can also use the genres of the movies to take into account. This can be calculated using Jaccard's Similarity. However, being in the same genre is not enough, since, within the genre, there are many different movie qualities, that are reflected by the ratings. Therefore, the Cosine Similarity can be used to determine the similarity of the rating. Only after calculating the 2 similarities, and they both satisfy a tolerance level, can there be a similar relationship between the movies.  

However, how can one compare the difference between these two methods? How can one check if they are actually good or not? In order to solve that, there will be a calculate of a baseline. This will be used as a brute force method, where it will always be solved, but the rating is not guaranteed to be precise. Since there are a split of 80/20 to create the Training users and Testing users, the baseline will be calculated for a Testing user by taking the average of all Training user who have seen and rated the movie. If the method yield a better prediction (closer, and more), then the method can be verified as a better way of predicting.

## **EXAMPLES:**
Given the datasets mentioned above in the Introduction part as the examples, here are the implementation of the solutions: 
 * MovieLens Small Dataset: 
### Step 1: Start the neo4j server 

![Terminal pic](https://github.com/Merith997/predict_rating/blob/master/Images/Initiate%20Neo4j%20to%20start.png)

Since the dataset is not a small one, the community edition is preferred, over the Desktop version.

### Step 2: Setting constraints and importing MovieLens data from GroupLens 

![Constraint](https://github.com/Merith997/predict_rating/blob/master/Images/Create%20constraints.png)
![Normalization](https://github.com/Merith997/predict_rating/blob/master/Images/import%20data%20and%20normalized.png)

To calculate faster, and avoid duplicates, the constraints are added above. In the process of importing the ratings from ratings.csv, the User class is also created to link their id and the ratings to respective movies.

### Step 3: After setting the constraints, initiate the relationships per methods 

#### Method 1 - Movie Similarity: 

![Similar_movie](https://github.com/Merith997/predict_rating/blob/master/Images/Similar%20movies.png)

In this case, the similarity depends on 2 factors: the common genres, and the user's rating of movies that are similar to those that the test user watched. 

The common genres are calculated by Jaccard Similarity, while the user's rating is based on cosine similarity. 

#### Method 2 - User Similarity: 

![User_neighbor](https://github.com/Merith997/predict_rating/blob/master/Images/User%20nearby.png)

In this case, the similarity depends on 1 factor: the common movies and their genres.

The common genres are calculated by Jaccard Similarity, while the user's rating is based on cosine similarity. 

### Step 4: Calculate the predictions and compile them to count the number of acceptable predictions 

#### Method 1's output:

![Similar_movie](https://github.com/Merith997/predict_rating/blob/master/Images/Screenshot%20from%202020-05-29%2011-52-18.png)

#### Method 2's output:

![Nearby_User](https://github.com/Merith997/predict_rating/blob/master/Images/Screenshot%20from%202020-05-29%2011-52-00.png)

At this step, the result above can be applied to any amount of users (as the id is inserted into the list, and can be changed anytime using the randomly selected user query). Above, the query returned a result as the user id, the respected number of prediction that perfectly matches the data, within 0.5 ratings, and then the rest. The mse column consists of the mean square error, which can be interpreted as the lower it is, the more precise the prediction is. 
The first column is the method where the predicted rating is created from simply taking an average of all the ratings of train users who watches that movie. The second column in the method's 1 output is predicted via the training data and the similar movie algorithm. 
From there, one can see that the algorithm, while not perfect, but usually produce a better prediction.

### Step 5: Export the data result as needed, in this case, to Gephi 

![Gephi](https://github.com/Merith997/predict_rating/blob/master/Images/screenshot_141147.png)

After using Gephi in conjunction with APOC's procedure query, the data can be visualized such as above. In this case, the picture shown is a presentation of how similar movies are to each other, and the size of the node is how many users rated it.

## **DRAWBACK:**
Currently, the prediction is based solely on the genre category, whereas incorporating the gnome would further detail the separation. This, however, is based on a scoring system, and therefore would need additional scoring between each relevant relationship seen above.

Another drawback mentioned above is the need of having a user's movie already in the dataset. However, predicting an already made movie is not as useful as one would want to be able to predict a new movie. Perhaps this is a problem in creating a movie, but not knowing how the public will receive it. However, to take into account new movies, the program will also need to be able to input data, and each time predicting, there would need to be a consideration to the old dataset, and how to accommodate newer ones. 

Last but not least, this method of prediction is based on the ratings of the users who are included in the dataset. These are chosen at random, however, they may or may not able to represent the true random of the people, nor the outliers, who would rate movies in their methods. Therefore, this method can only predict but not at a 100% success rate. In the future, this can be improved with more usage of statistics, and perhaps take into account the type of users, which then can consider the biases and improve prediction even more.

## **CONCLUSION:** 

As one can see by the end, the project has produced the result of the predictions close to more than half of the movies for each user on average. When simply averaging the train users' rating as the baseline, then the method of using similar movies can produce results almost always, and more than half of those predictions are better than the ones given by the baseline calculation. The method of finding similar users, however, is much more selective in producing results. It requires neighbours who can satisfy the condition stated in the code, and since this is a small dataset, the neighbour may not always exist. 

