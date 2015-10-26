#Script to retrieve whois information for a set of domains

devtools::install_github("hrbrmstr/ipapi")
library(ipapi)
library(XML)

domains <- read.csv("domains.csv")
domains <- cbind(domains, geolocate(domains[[1]]))

findDomain <- function(x){
    url <- paste(x, sep="")
    doc <- htmlParse(url, useInternalNodes=T)
    title <- doc["//title"]
    title
}

domains <- cbind(domains, sapply(domains[[1]], findDomain))
