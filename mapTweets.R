library(twitteR)
library(ggmap)

# Add your info here...
consumer_key <- "" 
consumer_secret <- "" 
access_token <- "" 
access_secret <- "" 


#Adjustment only for Windows 
#see: http://davetang.org/muse/2013/04/06/using-the-r_twitter-package/ 
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem") 


setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret) 


myChar <- "jokes" #Your search string 
mySearch <- searchTwitter(myChar, n=1000) 

#In mySearch you can get latitude and longitude but not all tweets are geolocated.
#Then, it's better to get the location from the user profile.
#However, you should expect many users will not be geolocatable.

tweets <- data.frame()
for (i in 1:100){
  tweets[i, "user"]<-mySearch[[i]]$screenName
  tweets[i, "text"]<-mySearch[[i]]$text
  tweets[i, "created"]<-as.POSIXct(mySearch[[i]]$created)
  tweets[i, "location"]<-location(getUser(mySearch[[i]]$screenName))
  tweets[i, "lat"]<-geocode(tweets[i, "location"], messaging = FALSE)$lat
  tweets[i, "lon"]<-geocode(tweets[i, "location"], messaging = FALSE)$lon
}

# Count tweets without (user) geolocation
nrow(subset(tweets, is.na(tweets$lat)==TRUE))

# UK Map - change at will
map<-get_map(location="UK", zoom = 6)

mapPoints <- ggmap(map) +
             geom_point(aes(x = tweets$lon, y = tweets$lat),
                        data = tweets,
                        size = 2,
                        alpha = 0.5)
mapPoints
