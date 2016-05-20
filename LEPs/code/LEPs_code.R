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
pg_cols <- paste(var_desc$ColumnVariableCode, ifelse(var_desc$ColumnVariableMeasurementUnit == "Sum", "decimal",
                                                     ifelse(var_desc$ColumnVariableMeasurementUnit == "Ratio", "decimal",
                                                            ifelse(var_desc$ColumnVariableMeasurementUnit == "Percentage", "decimal",
                                                                   ifelse(var_desc$ColumnVariableMeasurementUnit == "Years", "decimal",
                                                                          ifelse(var_desc$ColumnVariableMeasurementUnit == "Average", "decimal","integer"))))), sep = " ")

lookup <- read.csv("m_code/ckan/lookup.csv")
lookup$LAD11NM <- ifelse(lookup$LAD11NM =="King's Lynn and West Norfolk","Kings Lynn and West Norfolk",as.character(lookup$LAD11NM))
lookup_lad <- unique(lookup[,c("LAD11CD", "LAD11NM")])

# Four LAD codes have different codes. Next line creates an extra column with the edited codes as recorded on the official LEPs documents 
lookup_lad$LAD11LEPS <- ifelse(lookup_lad$LAD11CD=="E07000097","E07000242", 
                                 ifelse(lookup_lad$LAD11CD=="E07000100","E07000240", 
                                          ifelse(lookup_lad$LAD11CD=="E07000101","E07000243", 
                                                 ifelse(lookup_lad$LAD11CD=="E07000104","E07000241", as.character(lookup_lad$LAD11CD)))))
lookup_lad$lepid <- leps_lut[match(lookup_lad$LAD11LEPS, leps_lut$ons_lacode_new),6]

# Create tables in PostGIS for the Census CDRC Data Packs
for (i in 1:nrow(pg_tables[1])){
  var_lst <- paste(grep(pg_tables$pg_tables[i], pg_cols, value=TRUE), collapse = ', ')
  
  # Create OA tables
  odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_oa;"))
  odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_oa (GeographyCode varchar, ", var_lst, ");")) 
  
  # Create LSOA tables
  if (pg_tables$pg_tables[i]=="KS403EW"){
    var_lst <- gsub("KS403EW0006 decimal,","",var_lst)
    var_lst <- gsub("KS403EW0007 decimal,","",var_lst)
    var_lst <- gsub("KS403EW0008 decimal,","",var_lst)
    odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_lsoa;"))
    odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_lsoa (GeographyCode varchar, ", var_lst, ");"))
  } else {
    if (pg_tables$pg_tables[i]=="KS102EW"){
      var_lst <- gsub("KS102EW0018 decimal,","",var_lst)
      var_lst <- gsub("KS102EW0019 decimal,","",var_lst)
      odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_lsoa;"))
      odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_lsoa (GeographyCode varchar, ", var_lst, ");"))
    } else {
      odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_lsoa;"))
      odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_lsoa (GeographyCode varchar, ", var_lst, ");"))
    }
  }
  
  # Create MSOA tables
  if (pg_tables$pg_tables[i]=="KS403EW"){
    var_lst <- gsub("KS403EW0006 decimal,","",var_lst)
    var_lst <- gsub("KS403EW0007 decimal,","",var_lst)
    var_lst <- gsub("KS403EW0008 decimal,","",var_lst)
    
    odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_msoa;"))
    odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_msoa (GeographyCode varchar, ", var_lst, ");"))
  } else {
    if (pg_tables$pg_tables[i]=="KS102EW"){
      var_lst <- gsub("KS102EW0018 decimal,","",var_lst)
      var_lst <- gsub("KS102EW0019 decimal,","",var_lst)
      odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_msoa;"))
      odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_msoa (GeographyCode varchar, ", var_lst, ");"))
    } else {
      odbcQuery(con, paste0("DROP TABLE IF EXISTS ",pg_tables$pg_tables[i],"_msoa;"))
      odbcQuery(con, paste0("CREATE TABLE ",pg_tables$pg_tables[i],"_msoa (GeographyCode varchar, ", var_lst, ");"))
    }
  }
}

# Load Census CDRC Data Pack CSVs in PostGIS
for (i in 1:nrow(lookup_lad[2])){
  
  dir <- as.character(lookup_lad$LAD11NM[i])
  print(paste0(i,": Load the CSV files of ",dir))
  
  for (x in 1:nrow(pg_tables[1])){
    tb <- as.character(tolower(pg_tables$pg_tables[x])) 
    
    stat <- odbcQuery(con, paste0("COPY ",tb,"_oa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                                  as.character(pg_tables$pg_tables[x]),"_oa11.csv' DELIMITER ',' CSV HEADER;"))
    if (stat == -1L) {
      print(odbcGetErrMsg(con))
      odbcClearError(con)
    }
    stat <- odbcQuery(con, paste0("COPY ",tb,"_lsoa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                                  as.character(pg_tables$pg_tables[x]),"_lsoa11.csv' DELIMITER ',' CSV HEADER;"))
    if (stat == -1L) {
      print(odbcGetErrMsg(con))
      odbcClearError(con)
    }
    stat <- odbcQuery(con, paste0("COPY ",tb,"_msoa FROM '", getwd(),"/s_data/england_wales_zip/", dir, "/tables/", 
                                  as.character(pg_tables$pg_tables[x]),"_msoa11.csv' DELIMITER ',' CSV HEADER;"))
    if (stat == -1L) {
      print(odbcGetErrMsg(con))
      odbcClearError(con)
    }
  }
}

# Create indices 
for (x in 1:nrow(pg_tables[1])){
  tb <- as.character(tolower(pg_tables$pg_tables[x])) 
  
  stat <- odbcQuery(con, paste0("CREATE INDEX ",tb ,"_oa_geocode_index ON ", tb, "_oa (geographycode);"))
  if (stat == -1L) {
    print(odbcGetErrMsg(con))
    odbcClearError(con)
  }
  stat <- odbcQuery(con, paste0("CREATE INDEX ",tb ,"_lsoa_geocode_index ON ", tb, "_lsoa (geographycode);"))
  if (stat == -1L) {
    print(odbcGetErrMsg(con))
    odbcClearError(con)
  }
  stat <- odbcQuery(con, paste0("CREATE INDEX ",tb ,"_msoa_geocode_index ON ", tb, "_msoa (geographycode);"))
  if (stat == -1L) {
    print(odbcGetErrMsg(con))
    odbcClearError(con)
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
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "oa11", "_oa11.shp", index = FALSE)
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "msoa11", "_msoa11.shp", index = FALSE)
    import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "lsoa11", "_lsoa11.shp", index = FALSE)
  } else {
    if (i==nrow(lookup_lad[2])){
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "oa11", "_oa11.shp", append=TRUE)
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "msoa11", "_msoa11.shp", append=TRUE)
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "lsoa11", "_lsoa11.shp", append=TRUE)
    } else{
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "oa11", "_oa11.shp", append=TRUE, index = FALSE)
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "msoa11", "_msoa11.shp", append=TRUE, index = FALSE)
      import_or_append(con, paste(getwd(),"/s_data/england_wales_zip/", dir, "/shapefiles/", sep = ""), "lsoa11", "_lsoa11.shp", append=TRUE, index = FALSE)
    }
  }
}

# Check for invalid geometries
check_geometries(con,"oa11")
check_geometries(con,"msoa11")
check_geometries(con,"lsoa11")

# Create LEP directories

dir.create("/media/kd/Data/temp/LEPs/tables")
dir.create("/media/kd/Data/temp/LEPs/shapefiles")

for (i in leps_ids[,1]){
  print(i)
  lep_tb_path <- paste0("/media/kd/Data/temp/LEPs/tables/LEP",as.character(i))
  dir.create(lep_tb_path)
}

# Extract Census tables
for (i in leps_ids[15:39,1]){
  print(i)
  
  lep_tb_path <- paste0("/media/kd/Data/temp/LEPs/tables/LEP",as.character(i))
  
  v_lads <- data.frame(lookup_lad[lookup_lad$lepid == i,1])
  v_lads <- v_lads[complete.cases(v_lads),]
  v_lads <- data.frame(v_lads)
  
  field_value_oa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),1]))
  
  field_value_lsoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),2]))
  
  field_value_msoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),4]))

  for (x in 1:nrow(pg_tables[1])){
    tb <- as.character(tolower(pg_tables$pg_tables[x]))
    get_subset_table(paste0(tb,"_oa"), "geographycode", field_value_oa, paste0(lep_tb_path,"/",toupper(tb),"_oa11.csv"),con)
    get_subset_table(paste0(tb,"_lsoa"), "geographycode", field_value_lsoa, paste0(lep_tb_path,"/",toupper(tb),"_lsoa11.csv"),con)
    get_subset_table(paste0(tb,"_msoa"), "geographycode", field_value_msoa, paste0(lep_tb_path,"/",toupper(tb),"_msoa11.csv"),con)
  }
}









