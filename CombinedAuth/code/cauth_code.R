source("/media/kd/Data/Dropbox/Repos/r_source/postgis_functions.r")

setwd("/media/kd/Data/Dropbox/Repos/rds/")
# setwd("D:/Dropbox/Repos/rds/")

pwd <- readline(prompt="Enter Postgres password: ")
# Read Combined Authorities lookup table
cauth_lut <- read.csv(paste(getwd(),"/CombinedAuth/cauth.csv", sep = ""), sep="|")

lookup <- read.csv("m_code/ckan/lookup.csv")
lookup$LAD11NM <- ifelse(lookup$LAD11NM =="King's Lynn and West Norfolk","Kings Lynn and West Norfolk",as.character(lookup$LAD11NM))
lookup_lad <- unique(lookup[,c("LAD11CD", "LAD11NM")])

cauth_lut$ladid <- lookup_lad[match(cauth_lut$lad,lookup_lad$LAD11NM),1]
cauth_lut$n_ladid <- ifelse(cauth_lut$ladid == "E08000020", "E08000037", ifelse(cauth_lut$ladid == "E06000048", "E06000057",as.character(cauth_lut$ladid)))
write.table(cauth_lut, file = paste(getwd(),"/CombinedAuth/cauth_lut.csv", sep = ""), row.names=FALSE, quote = FALSE, na="", sep="|")

cauthids <- unique(cauth_lut[,c("cauthid", "cauth")])

# Add OAs and LADs in PostGIS

con <- odbcConnect("cdrcdb", uid = "kd", pwd= pwd)
username <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[5], "="))[2]
db_name <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[2], "="))[2]

# Add CombinedAuth lookup table in PostGIS
csv_types <- "cauthid varchar, cauth varchar, lad varchar, ladid varchar, n_ladid varchar"
odbcQuery(con, "DROP TABLE IF EXISTS cauth_lut;")
import_csv(con,paste(getwd(),"/CombinedAuth", sep = ""), "cauth_lut","cauth_lut.csv",csv_types,"|")

# Join CombinedAuth lut to LADs
odbcQuery(con, "DROP TABLE IF EXISTS lad_cauth;")
odbcQuery(con, "CREATE TABLE lad_cauth AS SELECT * FROM lads RIGHT JOIN cauth_lut ON (cauth_lut.n_ladid = lads.code);")

# Dissolve LADs to CombinedAuth regions (overlaped polygons)
odbcQuery(con, "DROP TABLE IF EXISTS cauth_fin;")
odbcQuery(con, "CREATE TABLE cauth_fin AS SELECT ST_UnaryUnion(ST_Collect(geom)), lad_cauth.cauthid, lad_cauth.cauth FROM lad_cauth  GROUP BY lad_cauth.cauth, lad_cauth.cauthid;")

# Export CombinedAuth shapefile
system(paste0('pgsql2shp -f ', getwd(), '/CombinedAuth/data/CombinedAuth.shp -h localhost -u ', username, ' -P ', pwd, ' ', db_name,' "SELECT * FROM cauth_fin"'))
 

# Prepare the lookup tables
var_desc <- read.csv("m_code/ckan/var_desc.csv")
pg_tables <- unique(var_desc$DatasetId)
pg_tables <- data.frame(pg_tables)
pg_cols <- paste(var_desc$ColumnVariableCode, ifelse(var_desc$ColumnVariableMeasurementUnit == "Sum", "decimal",
                                                     ifelse(var_desc$ColumnVariableMeasurementUnit == "Ratio", "decimal",
                                                            ifelse(var_desc$ColumnVariableMeasurementUnit == "Percentage", "decimal",
                                                                   ifelse(var_desc$ColumnVariableMeasurementUnit == "Years", "decimal",
                                                                          ifelse(var_desc$ColumnVariableMeasurementUnit == "Average", "decimal","integer"))))), sep = " ")

# Create CombinedAuth directories
for (i in cauthids[,1]){
  print(i)
  cauth_tb_path <- paste0("/media/kd/Data/temp/CombinedAuth/CombAuth",as.character(i))
  dir.create(cauth_tb_path)
}

for (i in cauthids[,1]){
  print(i)
  cauth_tb_path <- paste0("/media/kd/Data/temp/CombinedAuth/CombAuth",as.character(i),"/tables/")
  dir.create(cauth_tb_path)
}

for (i in cauthids[,1]){
  print(i)
  cauth_tb_path <- paste0("/media/kd/Data/temp/CombinedAuth/CombAuth",as.character(i),"/shapefiles/")
  dir.create(cauth_tb_path)
}

# Extract Census tables
for (i in cauthids[,1]){
  print(i)
  
  cauth_tb_path <- paste0("/media/kd/Data/temp/CombinedAuth/CombAuth",as.character(i), "/tables")
  
  v_lads <- data.frame(cauth_lut[cauth_lut$cauthid == i,4])
  v_lads <- v_lads[complete.cases(v_lads),]
  v_lads <- data.frame(v_lads)
  
  field_value_oa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),1]))
  
  field_value_lsoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),2]))
  
  field_value_msoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),4]))

  for (x in 1:nrow(pg_tables[1])){
    tb <- as.character(tolower(pg_tables$pg_tables[x]))
    get_subset_table(paste0(tb,"_oa"), "geographycode", field_value_oa, paste0(cauth_tb_path,"/",toupper(tb),"_oa11.csv"),con)
    get_subset_table(paste0(tb,"_lsoa"), "geographycode", field_value_lsoa, paste0(cauth_tb_path,"/",toupper(tb),"_lsoa11.csv"),con)
    get_subset_table(paste0(tb,"_msoa"), "geographycode", field_value_msoa, paste0(cauth_tb_path,"/",toupper(tb),"_msoa11.csv"),con)
  }
}

# Extract LEP's Shapefiles for OA,LSOA & MSOA geographies
for (i in cauthids[,1]){
  print(i)
  
  cauth_tb_path <- paste0("/media/kd/Data/temp/CombinedAuth/CombAuth",as.character(i), "/shapefiles")
  
  v_lads <- data.frame(cauth_lut[cauth_lut$cauthid == i,4])
  v_lads <- v_lads[complete.cases(v_lads),]
  v_lads <- data.frame(v_lads)
  
  field_value_oa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),1]))
  
  field_value_lsoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),2]))
  
  field_value_msoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),4]))

  tb <- tolower(paste0("CombAuth",as.character(i)))
  get_subset_geo(paste0("oa11"), "oa11cd", field_value_oa, paste0(cauth_tb_path,"/",toupper(tb),"_oa11.shp"),con,pwd)
  get_subset_geo(paste0("lsoa11"), "lsoa11cd", field_value_lsoa, paste0(cauth_tb_path,"/",toupper(tb),"_lsoa11.shp"),con,pwd)
  get_subset_geo(paste0("msoa11"), "msoa11cd", field_value_msoa, paste0(cauth_tb_path,"/",toupper(tb),"_msoa11.shp"),con,pwd)

}








