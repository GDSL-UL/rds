source("/media/kd/Data/Dropbox/Repos/r_source/postgis_functions.r")

setwd("/media/kd/Data/Dropbox/Repos/rds/")
# setwd("D:/Dropbox/Repos/rds/")

pwd <- readline(prompt="Enter Postgres password: ")
# Read Northern Powerhouse lookup table
np_lut <- read.csv(paste(getwd(),"/NPowerhouse/np.csv", sep = ""), sep="|")

lookup <- read.csv("m_code/ckan/lookup.csv")
lookup$LAD11NM <- ifelse(lookup$LAD11NM =="King's Lynn and West Norfolk","Kings Lynn and West Norfolk",as.character(lookup$LAD11NM))
lookup_lad <- unique(lookup[,c("LAD11CD", "LAD11NM")])

np_lut$ladid <- lookup_lad[match(np_lut$lad,lookup_lad$LAD11NM),1]
np_lut$n_ladid <- ifelse(np_lut$ladid == "E08000020", "E08000037", ifelse(np_lut$ladid == "E06000048", "E06000057",as.character(np_lut$ladid)))
write.table(np_lut, file = paste(getwd(),"/NPowerhouse/np_lut.csv", sep = ""), row.names=FALSE, quote = FALSE, na="", sep="|")

npids <- unique(np_lut[,c("npid", "np")])

# Add OAs and LADs in PostGIS

con <- odbcConnect("cdrcdb", uid = "kd", pwd= pwd)
username <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[5], "="))[2]
db_name <- unlist(strsplit(unlist(strsplit(attributes(con)$connection.string, ";"))[2], "="))[2]

# Add Northern Powerhouse lookup table in PostGIS
csv_types <- "npid varchar, np varchar, lad varchar, ladid varchar, n_ladid varchar"
odbcQuery(con, "DROP TABLE IF EXISTS np_lut;")
import_csv(con,paste(getwd(),"/NPowerhouse", sep = ""), "np_lut","np_lut.csv",csv_types,"|")

# Join Northern Powerhouse lut to LADs
odbcQuery(con, "DROP TABLE IF EXISTS lad_np;")
odbcQuery(con, "CREATE TABLE lad_np AS SELECT * FROM lads RIGHT JOIN np_lut ON (np_lut.n_ladid = lads.code);")

# Dissolve LADs to Northern Powerhouse regions (overlaped polygons)
odbcQuery(con, "DROP TABLE IF EXISTS np_fin;")
odbcQuery(con, "CREATE TABLE np_fin AS SELECT ST_UnaryUnion(ST_Collect(geom)), lad_np.npid, lad_np.np FROM lad_np  GROUP BY lad_np.np, lad_np.npid;")

# Export Northern Powerhouse shapefile
system(paste0('pgsql2shp -f ', getwd(), '/NPowerhouse/data/NPowerhouse.shp -h localhost -u ', username, ' -P ', pwd, ' ', db_name,' "SELECT * FROM np_fin"'))
 

# Prepare the lookup tables
var_desc <- read.csv("m_code/ckan/var_desc.csv")
pg_tables <- unique(var_desc$DatasetId)
pg_tables <- data.frame(pg_tables)
pg_cols <- paste(var_desc$ColumnVariableCode, ifelse(var_desc$ColumnVariableMeasurementUnit == "Sum", "decimal",
                                                     ifelse(var_desc$ColumnVariableMeasurementUnit == "Ratio", "decimal",
                                                            ifelse(var_desc$ColumnVariableMeasurementUnit == "Percentage", "decimal",
                                                                   ifelse(var_desc$ColumnVariableMeasurementUnit == "Years", "decimal",
                                                                          ifelse(var_desc$ColumnVariableMeasurementUnit == "Average", "decimal","integer"))))), sep = " ")

# Create Northern Powerhouse directories
for (i in npids[,1]){
  print(i)
  np_tb_path <- paste0("/media/kd/Data/temp/NPowerhouse/NP",as.character(i))
  dir.create(np_tb_path)
}

for (i in npids[,1]){
  print(i)
  np_tb_path <- paste0("/media/kd/Data/temp/NPowerhouse/NP",as.character(i),"/tables/")
  dir.create(np_tb_path)
}

for (i in npids[,1]){
  print(i)
  np_tb_path <- paste0("/media/kd/Data/temp/NPowerhouse/NP",as.character(i),"/shapefiles/")
  dir.create(np_tb_path)
}

# Extract Census tables
for (i in npids[,1]){
  print(i)
  
  np_tb_path <- paste0("/media/kd/Data/temp/NPowerhouse/NP",as.character(i), "/tables")
  
  v_lads <- data.frame(np_lut[np_lut$npid == i,4])
  v_lads <- v_lads[complete.cases(v_lads),]
  v_lads <- data.frame(v_lads)
  
  field_value_oa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),1]))
  
  field_value_lsoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),2]))
  
  field_value_msoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),4]))

  for (x in 1:nrow(pg_tables[1])){
    tb <- as.character(tolower(pg_tables$pg_tables[x]))
    get_subset_table(paste0(tb,"_oa"), "geographycode", field_value_oa, paste0(np_tb_path,"/",toupper(tb),"_oa11.csv"),con)
    get_subset_table(paste0(tb,"_lsoa"), "geographycode", field_value_lsoa, paste0(np_tb_path,"/",toupper(tb),"_lsoa11.csv"),con)
    get_subset_table(paste0(tb,"_msoa"), "geographycode", field_value_msoa, paste0(np_tb_path,"/",toupper(tb),"_msoa11.csv"),con)
  }
}

# Extract Northern Powerhouse's shapefiles for OA,LSOA & MSOA geographies
for (i in npids[,1]){
  print(i)
  
  np_tb_path <- paste0("/media/kd/Data/temp/NPowerhouse/NP",as.character(i), "/shapefiles")
  
  v_lads <- data.frame(np_lut[np_lut$npid == i,4])
  v_lads <- v_lads[complete.cases(v_lads),]
  v_lads <- data.frame(v_lads)
  
  field_value_oa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),1]))
  
  field_value_lsoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),2]))
  
  field_value_msoa <- as.character(unique(lookup[ which( lookup$LAD11CD %in% v_lads$v_lads ),4]))

  tb <- tolower(paste0("NP",as.character(i)))
  get_subset_geo(paste0("oa11"), "oa11cd", field_value_oa, paste0(np_tb_path,"/",toupper(tb),"_oa11.shp"),con,pwd)
  get_subset_geo(paste0("lsoa11"), "lsoa11cd", field_value_lsoa, paste0(np_tb_path,"/",toupper(tb),"_lsoa11.shp"),con,pwd)
  get_subset_geo(paste0("msoa11"), "msoa11cd", field_value_msoa, paste0(np_tb_path,"/",toupper(tb),"_msoa11.shp"),con,pwd)

}








