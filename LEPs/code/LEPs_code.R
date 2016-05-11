source("source/postgis_functions.r")
library(rgeos)
library(rgdal)
library(dplyr)


# Read LEPs lookup table
leps_lut <- read.csv("/media/kd/Data/Dropbox/Repos/rds/LEPs/leps.csv", sep="|")

# Add OAs and LADs in PostGIS
db <- create_db("cdrcdb", "postgres", "kd")
con <- odbcConnect("cdrcdb", uid = "postgres", pwd="kd")
 
import_or_append(con, "/media/kd/Data/Dropbox/Repos/rds/s_data", "oa2011", "england_oa_2011_gen.shp")
import_or_append(con, "/media/kd/Data/Dropbox/Repos/rds/s_data", "lads", "district_borough_unitary_region.shp")

# Add LEPs lookup table in PostGIS
csv_types <- "lep varchar, la_name varchar, ons_lacode_old varchar, ons_lacode_new varchar, mleps integer"
import_csv(con,"/media/kd/Data/Dropbox/Repos/rds/LEPs", "leps_lut","leps.csv",csv_types,"|")