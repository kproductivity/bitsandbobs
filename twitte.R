###########################
# Install needed packages #
###########################

install.pkgs <- function(x){
    if (!require(x, character.only = TRUE)){
        install.packages(x)
    }
    require(x, character.only = TRUE)
}

update.packages() #this is recommended before installing any package
pkgs <- c("twitteR", "textcat", "tm", "tau", "wordcloud")
sapply(pkgs, install.pkgs)


###################################
# Function to retrieve the APIKEY #
###################################

readAPIkey <- function(){
  if(file.exists("twitter.key") == TRUE){                  # if apikey is already recorded
    apikey = as.character(read.csv("twitter.key",
                                   header = TRUE)$x)       # read it
  } else {                                                 # otherwise, ask for it
    apikey <- vector(mode="character", length=4)
    apikey[1] = readline("Consumer key   :")   
    apikey[2] = readline("Consumer secret:")
    apikey[3] = readline("Access token   :") 
    apikey[4] = readline("Access secret  :") 
    write.csv(apikey, "twitter.key",
              row.names = FALSE)                          # and write it in the file
  }
  apikey
}


#######################
# Retrieve the tweets #
#######################

apikey <- readAPIkey()

consumer_key <- apikey[1]
consumer_secret <- apikey[2]
access_token <- apikey[3]
access_secret <- apikey[4]

#Adjustment only for Windows
#see: http://davetang.org/muse/2013/04/06/using-the-r_twitter-package/
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem")

setup_twitter_oauth(consumer_key,
                    consumer_secret,
                    access_token,
                    access_secret)

myChar <- "reutersreplyallgate" #Your search string
mySearch <- searchTwitter(myChar, n=10000)


######################
# Analyse the tweets #
######################

#mySearch.df <- twListToDF(mySearch)
#mySearchUsers <- mySearch.df$screenName

createCorpus <- function(myTwitterSearch, exclude){
    
    mySearchText <- sapply(myTwitterSearch, function(x) x$getText())
    
    #Clean urls
    #see: http://stackoverflow.com/a/31703863/5252361
    mySearchText <- gsub("(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", mySearchText)
    
    #Clean "'s"
    #see: http://stackoverflow.com/a/15255751/5252361
    mySearchText <- gsub("['|`]s", "", mySearchText)
    
    #Keep only English tweets
    whichLanguage <- sapply(mySearchText, textcat)
    mySearchText <- mySearchText[which(whichLanguage[]=="english")]
    
    #Convert non-convertible bytes with hex codes
    #Adapted from http://stackoverflow.com/a/11633398/5252361
    mySearchText <- sapply(mySearchText,
                           function(x) iconv(enc2utf8(x), sub = "byte"))
    
    mySearchCorpus <- Corpus(VectorSource(mySearchText))
    
    #Build list of words to filter out, including a possible exclude
    myStopwords <- c("rt", exclude)
    
    mySearchCorpus <- tm_map(mySearchCorpus, content_transformer(tolower))
    mySearchCorpus <- tm_map(mySearchCorpus, removeWords, myStopwords)
    mySearchCorpus <- tm_map(mySearchCorpus,
                             function(x) removeWords(x,stopwords("english")))
    mySearchCorpus <- tm_map(mySearchCorpus, removeNumbers)
    mySearchCorpus <- tm_map(mySearchCorpus, removePunctuation)
    mySearchCorpus <- tm_map(mySearchCorpus, stripWhitespace)
}

myCorpus <- createCorpus(mySearch, exclude=myChar)

#Unigrams
tdm <- TermDocumentMatrix(myCorpus)
findFreqTerms(tdm, 5)

png("wordcloud.png", width=1280,height=800)
wordcloud(myCorpus, min.freq=5, max.words=50)
dev.off()

#Bigrams | I'm using a different package for experimentation
myCorpusText <- data.frame(text=unlist(sapply(myCorpus,
                                              `[`, "content")),
                           stringsAsFactors=F)

bigrams <- textcnt(myCorpusText, n=2L, method = "string")
bigrams <- data.frame(counts = unclass(bigrams), size = nchar(names(bigrams)))

png("wordcloud.png", width=1280,height=800)
wordcloud(rownames(bigrams), bigrams$counts, min.freq=4, max.words=50)
dev.off()
