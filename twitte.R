#Install needed packages
install.pkgs <- function(x){
    if (!require(x, character.only = TRUE)){
        install.packages(x)
    }
    require(x, character.only = TRUE)
}

#update.packages()
pkgs <- c("twitteR", "tm", "stringi", "tau", "wordcloud")
sapply(pkgs, install.pkgs)
    


#Only for Windows
#see: http://davetang.org/muse/2013/04/06/using-the-r_twitter-package/
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem")

#Fill these with your keys.
consumer_key <- 'xxxx'
consumer_secret <- 'xxxx'
access_token <- 'xxxx'
access_secret <- 'xxxx'

setup_twitter_oauth(consumer_key,
                    consumer_secret,
                    access_token,
                    access_secret)


myChar <- "volatility"
mySearch <- searchTwitter(myChar, n=1000)

#mySearch.df <- twListToDF(mySearch)
#mySearchUsers <- mySearch.df$screenName

createCorpus <- function(myTwitterSearch){
    
    #Clean urls
    #see: http://stackoverflow.com/a/31703863/5252361
    mySearchText <- sapply(myTwitterSearch, function(x) x$getText())
    mySearchText <- gsub("(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", mySearchText)
    
    mySearchCorpus <- Corpus(VectorSource(mySearchText))
    
    #Build list of words to filter out
    myStopwords <- c("RT")
    
    #Use package stringi since its tolower works with non-UTF
    #see: http://stackoverflow.com/a/27765192/5252361
    mySearchCorpus <- tm_map(mySearchCorpus, content_transformer(stri_trans_tolower))

    mySearchCorpus <- tm_map(mySearchCorpus,
                             function(x) removeWords(x,stopwords("english")))
    mySearchCorpus <- tm_map(mySearchCorpus, removeWords, myStopwords)
    mySearchCorpus <- tm_map(mySearchCorpus, removeNumbers)
    mySearchCorpus <- tm_map(mySearchCorpus, removePunctuation)
    mySearchCorpus <- tm_map(mySearchCorpus, stripWhitespace)
}

myCorpus <- createCorpus(mySearch)
tdm <- TermDocumentMatrix(myCorpus)

findFreqTerms(tdm, 5)

wordcloud(myCorpus, min.freq=5, max.words=75)

#Playing with bigrams
BigramTokenizer <-
    function(x)
        unlist(lapply(ngrams(words(x), 2), paste, collapse = " "),
               use.names = FALSE)

tdm2 <- TermDocumentMatrix(myCorpus,
                           control = list(tokenize = BigramTokenizer))

tdm2b <- removeSparseTerms(tdm2, 0.9)
inspect(tdm2b)
