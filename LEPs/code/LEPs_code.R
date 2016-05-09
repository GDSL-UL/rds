
library(rgeos)
library(rgdal)
library(dplyr)

# Download OA 2011 shapefile. 
download.file("https://census.edina.ac.uk/ukborders/easy_download/prebuilt/shape/England_oa_2011_gen.zip",
              destfile = "oa11gen.zip")
unzip("oa11gen.zip", exdir = ".")
oa11gen <- readOGR(".", "england_oa_2011_gen")

uregions <- readOGR(".","district_borough_unitary_ward_region")
plot(uregions)

leps_lut <- read.csv("/media/kd/Data/Repos/rds/LEPs/leps.csv", sep="|")