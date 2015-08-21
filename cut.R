#Trick to start cutting timestamps on the 00 minute.

myTime <- c("20-08-2014 07:15", 
            "20-08-2014 07:25",
            "20-08-2014 07:30",
            "20-08-2014 07:34", 
            "20-08-2014 07:47",
            "20-08-2014 07:59")
myTime <- strptime(myTime, format="%d-%m-%Y %H:%M")

#This is wrong, since it will start at 7:15
thirtyMinutes <- cut.POSIXt(myTime, breaks="30 min")

#This has been adjusted to 00 and 30
#As simple as adjust the first time of the ts to 00
library(lubridate)
#just trick the algorithm
myOrigin <- myTime[1]
myTime[1] <- ifelse (minute(myOrigin)<30,
                     myOrigin-minute(myOrigin)*60, #reset to 00
                     ifelse(minute(myOrigin)>30,   
                            myOrigin-(minute(myOrigin)+30)*60), #reset to 30
                            myOrigin) #unless it is already 30
thirtyMinutes <- cut.POSIXt(myTime, breaks="30 min")
