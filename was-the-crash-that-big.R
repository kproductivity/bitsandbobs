#Trying to replicate the diagrams in
#http://www.economist.com/blogs/freeexchange/2015/08/chinas-stockmarket-0

install.packages("Quandl")
install.packages("RColorBrewer")

library(Quandl)
library(lattice)
library(reshape2)
library(RColorBrewer)

Sys.setlocale("LC_TIME", "C")

#Read data

Quandl.auth("xxxxYOURapiKEYxxxx")

SSEC <- Quandl("YAHOO/INDEX_SSEC",
                start_date="1997-07-02", type="zoo")

SP500 <- Quandl("YAHOO/INDEX_GSPC",
                 start_date="1950-01-03", type="zoo")

N225 <- Quandl("YAHOO/INDEX_N225",
                start_date="1984-01-04", type="zoo")

#Data obtained from Yahoo Finance
FTSE100 <- read.zoo("table.csv", header=TRUE, sep=",", format="%Y-%m-%d")
#FTSE100 <- read.csv("table.csv")
#FTSE100 <- as.zoo(FTSE100, order.by = FTSE100$Date)
#FTSE100 <- FTSE100[, -c(1)]


#Merge 4 indexes Adj.Close

indexes <- merge(SSEC=SSEC[,6],SP500=SP500[,6],
                 N225=N225[,6],FTSE100=FTSE100[,6], all=FALSE)

startDate <- as.Date("2000-01-01")
endDate <- as.Date("2015-08-31")
indexes <- window(indexes, start=startDate)


# Calculate returns, from adjusted close

returns <- function(x) 100*diff(log(x))

r.indexes <- returns(indexes)

summary(r.indexes)
plot(r.indexes)


hist(r.indexes[,1], breaks=20)
hist(r.indexes[,2], breaks=20)
hist(r.indexes[,3], breaks=20)
hist(r.indexes[,4], breaks=20)

#Prepare data for panel histogram
r.adj <- as.data.frame(r.indexes)
r.adj$id <- row.names(r.adj)
r.adj <- melt(r.adj, value.name="returns")

#Draw histograms
#See: http://www.magesblog.com/2012/12/changing-colours-and-legends-in-lattice.html
myColours <- brewer.pal(6,"Blues")
mySettings <- list(
    superpose.polygon=list(col=myColours[2:5], border="transparent"),
    strip.background=list(col=myColours[6]),
    strip.border=list(col="black")
)

#myCrash <- c(-4.61, -4.67, -8.49, -3.94) #As per The Economist
myCrash <- r.adj[r.adj$id=="2015-08-24",]

histogram(~returns|variable, data=r.adj, type="percent",
          xlab="adjusted returns (%) - Own source based on Yahoo Finance data from 04-01-2000",
          main="Was the crash that big?",
          nint=30,
          par.settings = mySettings,
          par.strip.text=list(col="white", font=2),
          layout=c(2,2),
          key=list(space="top", columns=2,
                   lines=list(col="red", lty=c("twodash", "solid"), lwd=1),
                   text=list(c("3 std.dev.","Black Monday returns (24-08-2015)"))),
          panel = function(x, ...) {
              mu=mean(x)
              sigma=sd(x)
              panel.abline(v=mu-3*sigma, lty = "twodash", col = "red")
              panel.abline(v=mu+3*sigma, lty = "twodash", col = "red")
              panel.abline(v=myCrash[panel.number(),]$returns,lty="solid",col="red")
              panel.histogram(x, ..., col = myColours[panel.number()])
          })
