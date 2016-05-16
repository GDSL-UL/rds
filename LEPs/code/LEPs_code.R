source("/media/kd/Data/Dropbox/Repos/r_source/postgis_functions.r")
library(rgeos)
library(rgdal)
library(dplyr)

setwd("/media/kd/Data/Dropbox/Repos/rds/")
# setwd("D:/Dropbox/Repos/rds/")

pwd <- readline(prompt="Enter Postgres password: ")
# Read LEPs lookup table
leps_lut <- read.csv(paste(getwd(),"/LEPs/leps.csv", sep = ""), sep="|")
leps_ids <- read.csv(paste(getwd(),"/LEPs/lepids.csv", sep = ""), sep="|", colClasses = c("character", "character"))
leps_lut$lepid <- leps_ids[match(leps_lut$lep, leps_ids$lepname),1]
write.table(leps_lut, file = paste(getwd(),"/LEPs/leps.csv", sep = ""), row.names=FALSE, quote = FALSE, na="", sep="|")

# Add OAs and LADs in PostGIS
db <- create_db("cdrcdb", "kd", pwd, spacetable= "open_path", extensions = c("POSTGIS"))
# test <- create_db("prescdb", "kd", pwd, spacetable= "safe_path", extensions = c("POSTGIS","POSTGIS_topology"))
con <- odbcConnect("cdrcdb", uid = "kd", pwd= pwd)
username <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[5], "="))[2]
db_name <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[2], "="))[2]
 
import_or_append(con, paste(getwd(),"/s_data", sep = ""), "oa2011", "england_oa_2011_gen.shp")
import_or_append(con, paste(getwd(),"/s_data", sep = ""), "lads", "district_borough_unitary_region.shp")

# Add LEPs lookup table in PostGIS
csv_types <- "lep varchar, la_name varchar, ons_lacode_old varchar, ons_lacode_new varchar, mleps integer, lepid varchar"
import_csv(con,paste(getwd(),"/LEPs", sep = ""), "leps_lut","leps.csv",csv_types,"|")

# Join LEPs lut to LADs
odbcQuery(con, "DROP TABLE IF EXISTS lad_lep;")
odbcQuery(con, "CREATE TABLE lad_lep AS SELECT * FROM lads RIGHT JOIN leps_lut ON (leps_lut.ons_lacode_new = lads.code);")

# Dissolve LADs to LEP regions (overlaped polygons)
odbcQuery(con, "DROP TABLE IF EXISTS leps_fin;")
odbcQuery(con, "CREATE TABLE leps_fin AS SELECT ST_UnaryUnion(ST_Collect(geom)), lad_lep.lepid, lad_lep.lep FROM lad_lep  GROUP BY lad_lep.lep, lad_lep.lepid;")

# Export LEPs shapefile
system(paste0('pgsql2shp -f ', getwd(), '/LEPs/data/leps.shp -h localhost -u ', username, ' -P ', pwd, ' ', db_name,' "SELECT * FROM leps_fin"'))
 

# Prepare the lookup tables
var_desc <- read.csv("m_code/ckan/var_desc.csv")
pg_tables <- unique(var_desc$DatasetId)
pg_tables <- data.frame(pg_tables)
pg_cols <- paste(var_desc$ColumnVariableCode, ifelse(var_desc$ColumnVariableMeasurementUnit == "Sum", "integer",
                                                     ifelse(var_desc$ColumnVariableMeasurementUnit == "Ratio", "decimal",
                                                            ifelse(var_desc$ColumnVariableMeasurementUnit == "Percentage", "decimal",
                                                                   ifelse(var_desc$ColumnVariableMeasurementUnit == "Years", "integer",
                                                                          ifelse(var_desc$ColumnVariableMeasurementUnit == "Average", "decimal","integer"))))), sep = " ")

lookup <- read.csv("m_code/ckan/lookup.csv")
lookup_lad <- unique(lookup[,c("LAD11CD", "LAD11NM")])
# Four LAD codes have different codes. Next line creates an extra column with the edited codes as recorded on the official LEPs documents 
lookup_lad$LAD11LEPS <- ifelse(lookup_lad$LAD11CD=="E07000097","E07000242", 
                                 ifelse(lookup_lad$LAD11CD=="E07000100","E07000240", 
                                          ifelse(lookup_lad$LAD11CD=="E07000101","E07000243", 
                                                 ifelse(lookup_lad$LAD11CD=="E07000104","E07000241", as.character(lookup_lad$LAD11CD)))))

# Create tables in PostGIS for the Census CDRC Data Packs
for (i in 1:nrow(pg_tables[1])){
  var_lst <- paste(grep(pg_tables$pg_tables[i],pg_cols, value=TRUE), collapse = ', ')
  # Create OA tables
  odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_oa;"))
  odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_oa (GeographyCode varchar, ", var_lst, ");"))
  # Create LSOA tables
  odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_lsoa;"))
  odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_lsoa (GeographyCode varchar, ", var_lst, ");"))
  # Create MSOA tables
  odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_msoa;"))
  odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_msoa (GeographyCode varchar, ", var_lst, ");"))
}

# Load Census CDRC Data Pack CSVs in PostGIS
for (i in 1:nrow(lookup_lad[2])){
  
  dir <- as.character(lookup_lad$LAD11NM[i])
  print(paste("Load the CSV files of",dir))
  
  for (x in 1:nrow(pg_tables[1])){
    tb <- as.character(tolower(pg_tables$pg_tables[x])) 
    odbcQuery(con, paste0("COPY ",tb,"_oa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                           as.character(pg_tables$pg_tables[x]),"_oa11.csv' DELIMITER ',' CSV HEADER;"))
    odbcQuery(con, paste0("COPY ",tb,"_lsoa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                          as.character(pg_tables$pg_tables[x]),"_lsoa11.csv' DELIMITER ',' CSV HEADER;"))
    odbcQuery(con, paste0("COPY ",tb,"_msoa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                          as.character(pg_tables$pg_tables[x]),"_msoa11.csv' DELIMITER ',' CSV HEADER;"))
  }
}

# Load OAs/LSOAs/MSOAs geographies

odbcQuery(con, "DROP TABLE IF EXISTS oa11;")
odbcQuery(con, "DROP TABLE IF EXISTS msoa11;")
odbcQuery(con, "DROP TABLE IF EXISTS lsoa11;")

for (i in 1:nrow(lookup_lad[2])){
  dir <- as.character(lookup_lad$LAD11NM[i])
  print(paste("Load the CSV files of",dir))
  if (i == 1){
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "oa11", "_oa11.shp")
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "msoa11", "_msoa11.shp")
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "lsoa11", "_lsoa11.shp")
  } else {
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "oa11", "_oa11.shp", append=TRUE)
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "msoa11", "_msoa11.shp", append=TRUE)
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "lsoa11", "_lsoa11.shp", append=TRUE)
  }
}

# Check for invalid geometries
check_geometries(con,"oa11")
check_geometries(con,"msoa11")
check_geometries(con,"lsoa11")
odbcCloseAll(con)











