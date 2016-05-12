source("source/postgis_functions.r")
library(rgeos)
library(rgdal)
library(dplyr)


# Read LEPs lookup table
leps_lut <- read.csv("/media/kd/Data/Dropbox/Repos/rds/LEPs/leps.csv", sep="|")
leps_ids <- read.csv("/media/kd/Data/Dropbox/Repos/rds/LEPs/lepids.csv", sep="|", colClasses = c("character", "character"))
leps_lut$lepid <- leps_ids[match(leps_lut$lep, leps_ids$lepname),1]
write.table(leps_lut, file = "/media/kd/Data/Dropbox/Repos/rds/LEPs/leps.csv",row.names=FALSE, quote = FALSE, na="", sep="|")

# Add OAs and LADs in PostGIS
db <- create_db("cdrcdb", "postgres", "kd")
con <- odbcConnect("cdrcdb", uid = "postgres", pwd="kd")
 
import_or_append(con, "/media/kd/Data/Dropbox/Repos/rds/s_data", "oa2011", "england_oa_2011_gen.shp")
import_or_append(con, "/media/kd/Data/Dropbox/Repos/rds/s_data", "lads", "district_borough_unitary_region.shp")

# Add LEPs lookup table in PostGIS
csv_types <- "lep varchar, la_name varchar, ons_lacode_old varchar, ons_lacode_new varchar, mleps integer, lepid varchar"
import_csv(con,"/media/kd/Data/Dropbox/Repos/rds/LEPs", "leps_lut","leps.csv",csv_types,"|")

# Join LEPs lut to LADs
odbcQuery(con, "DROP TABLE IF EXISTS lad_lep;")
odbcQuery(con, "CREATE TABLE lad_lep AS SELECT * FROM lads RIGHT JOIN leps_lut ON (leps_lut.ons_lacode_new = lads.code);")

# Dissolve LADs to LEP regions (overlaped polygons)
odbcQuery(con, "DROP TABLE IF EXISTS leps_fin;")
odbcQuery(con, "CREATE TABLE leps_fin AS SELECT ST_UnaryUnion(ST_Collect(geom)), lad_lep.lepid, lad_lep.lep FROM lad_lep  GROUP BY lad_lep.lep, lad_lep.lepid;")

# Export LEPs shapefile
 system('pgsql2shp -f /media/kd/Data/Dropbox/Repos/rds/LEPs/data/leps.shp -h localhost -u postgres -P kd cdrcdb "SELECT * FROM leps_fin"')