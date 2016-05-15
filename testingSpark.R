####################################################
# Testing SparkR - standalone Spark in R           #
# https://spark.apache.org/docs/latest/sparkr.html #
####################################################

# Loading the package
if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "/home/kproductivity/Spark")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))

# Initiate the cluster
sc <- sparkR.init(master = "local[*]",
                  sparkEnvir = list(spark.driver.memory="2g"),
                  sparkPackages="com.databricks:spark-csv_2.10:1.4.0")
                  ## CSV package: http://spark-packages.org/package/databricks/spark-csv
sqlContext <- sparkRSQL.init(sc)

# Download sample data
url <- "http://archive.ics.uci.edu/ml/machine-learning-databases/wine-quality/winequality-red.csv"
download.file(url, destfile = "wine.csv")

## https://github.com/databricks/spark-csv
wineDF <- read.df(sqlContext, "wine.csv", header="true",
                  source = "com.databricks.spark.csv", delimiter = ";")

# Show some basic info on the dataset
describe(wineDF, "pH")

# Stop the Spark context
sparkR.stop()
