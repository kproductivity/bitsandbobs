#See http://www.dealingdata.net/2016/07/23/PoGo-Series-Tweepy/

import sys
import os
import jsonpickle
import tweepy

#Authentication
auth = tweepy.AppAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_secret)

#Creating a twitter API wrapper using tweepy
#See http://docs.tweepy.org/en/v3.7.0/api.html
api = tweepy.API(auth, wait_on_rate_limit=True,wait_on_rate_limit_notify=True)

#Error handling
if (not api):
    print ("Problem connecting to API")

#Configuration
searchQuery = 'search this'
maxTweets = 1000000
tweetsPerQry = 100

#Set cursor to collect tweets
tweetCount = 0

#Open a text file to save the tweets to
with open('tweets.json', 'w') as f:

    for tweet in tweepy.Cursor(api.search,q=searchQuery).items(maxTweets) :         

        #Verify the tweet has [this_info] before writing
        #if tweet.[this_info] is not None:
            
            f.write(jsonpickle.encode(tweet._json, unpicklable=False) + '\n')
            tweetCount += 1

    #Display how many tweets we have collected
    print("Downloaded {0} tweets".format(tweetCount))
