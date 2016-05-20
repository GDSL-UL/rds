##########################################################################################################
#             Use census_packs2.r script to create census packs for 2011 Census                          #
#           Output readme.txt, datasets_descr.txt, json file, census tables and shapefiles               #
#                            for each LAD at the OA, LSOA, MSOA scales                                   #
##########################################################################################################
library(whisker)
source("/media/michalis/1BAE-C95B/liverpool/r_script/ckan/census_packs2.r")

setwd("~/liverpool/ckan/england")

############################################# Download and Unzip ##########################################
url <- 'https://www.nomisweb.co.uk/census/2011/bulk/r2_2'

zip_folder <- "zip_files"
oa_data <- "oa_data"

down_unzip(url, zip_folder, oa_data)

############################################## Create csv files ###########################################
lookup <- read.csv("~/liverpool/ckan/lookup.csv")

# lookup[lookup$LAD11NM == "Gateshead",][,"LAD11CD"] <- "E08000037"
# lookup[lookup$LAD11NM == "Northumberland",][,"LAD11CD"] <- "E06000057"
# lookup[lookup$LAD11NM == "Welwyn Hatfield",][,"LAD11CD"] <- "E07000241"
# lookup[lookup$LAD11NM == "St Albans",][,"LAD11CD"] <- "E07000240"
# lookup[lookup$LAD11NM == "Stevenage",][,"LAD11CD"] <- "E07000243"
# lookup[lookup$LAD11NM == "East Hertfordshire",][,"LAD11CD"] <- "E07000242"

dir.create("lad_data")

path_in <- paste(getwd(), "oa_data", sep="/")
path_out <- paste(getwd(), "lad_data", sep="/")

# create census tables as csv files for oa, msoa and lsoa per lad
create_census_packs(path_in, path_out, lookup)

############################################# Extract shapefiles ###########################################

msoa <- readOGR("/home/michalis/backup/GIS_Data/MSOAs_2011", "MSOA_2011_EW_BFC_V2")
msoa@data[,2] <- NULL
msoa@data[,2] <- NULL
lsoa <- readOGR("/home/michalis/backup/GIS_Data/LSOAs_2011", "LSOA_2011_EW_BFC_V2")
lsoa@data[,2] <- NULL
lsoa@data[,2] <- NULL
oa <- readOGR("/home/michalis/backup/GIS_Data/OAs_2011", "OA_2011_EW_BFC")

# extract boundaries
# bb_list <- extract_geog(oa, lookup, "OA11CD", path_out, create_bblist=T, create_dir=T)
extract_geog(oa, lookup, "OA11CD", path_out, create_dir=T)
extract_geog(msoa, lookup, "MSOA11CD", path_out)
extract_geog(lsoa, lookup, "LSOA11CD", path_out)

# bb_df <- as.data.frame(bb_list)
# bb_df <- as.data.frame(t(bb_df))
# bb_df$LAD11NM <- row.names(bb_df)
# write.csv(bb_df, "bounding_box.csv",row.names=F)
############################################## Create json file #############################################

# bb_df <- read.csv("bounding_box.csv")
# bb_df[,5] <- as.character(bb_df[,5])
# 
# for (lad in levels(bb_df$LAD11NM)){
#   title <- paste("Census of",lad)
#   description <- c("The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:",
#                        "Contains National Statistics data Crown copyright and database right [year]",
#                        "Contains Ordnance Survey data Crown copyright and database right [year]",
#                        paste('This census data pack provides 2011 Census estimates for the "Key Statistic" and "Quick Statistic" tables within the local authority district "',
#                        lad,'" at the OA, LSOA and MSOA scale.',sep=""),
#                        "The estimates are as at census day, 27 March 2011.",
#                        "Statistical Disclosure Control",
#                        "In order to protect against disclosure of personal information from the 2011 Census, there has been swapping of records in the Census database between different geographic areas and so some counts will be affected.",
#                        "In the main, the greatest effects will be at the lowest geographies, since the record swapping is targeted towards those households with unusual characteristics in small areas.",
#                        "More details on the ONS Census disclosure control strategy may be found on the Statistical Disclosure Control page on the ONS website:",
#                        "http://www.ons.gov.uk/ons/guide-method/census/2011/census-data/2011-census-prospectus/new-developments-for-2011-census-results/statistical-disclosure-control/index.html")
#   tag_string <- paste(lad,"census; 2011; Local Authority; demography; socio-economic; ethnicity; travel; religion; housing; education",sep="; ")
#   
#   bounding_box <- as.character(bb_df[bb_df[,6] == lad,][1:5])
#   names(bounding_box) <- names(bb_df)[1:5]
#   
#   json_list <- create_json(title=title, description=description, tag_string=tag_string, bounding_box=bounding_box)
#   write(toJSON(json_list), paste(path_out, "/", lad, "/", lad, ".json",sep=""))
# }

################################################################################################################
#                                  Create XML files for Census packs                                           #
################################################################################################################
setwd("~/liverpool/ckan")

# source("~/Dropbox/r_script/ckan/xml_ukds.r")
# 
# keys_df <- read.table("~/Dropbox/ckan/xml_lookup_en.csv", header = T, sep="\t", stringsAsFactors=F)
# xml_list <- xmlToList("~/Dropbox/ckan/DDI_example/UKDS-example-record.xml")
# 
# xml2 <- trim_xml(xml_list, keys_df)
# xml_list <- xml2[[1]]
# keys_df <- xml2[[2]]
# 
# lookup <- read.csv("lookup.csv", stringsAsFactors=F)
# lookup$Country <- as.character(ifelse(substr(lookup$OA11CD, 1, 1) == "E", "England", "Wales"))
# lookup <- unique(lookup[,c("LAD11NM", "Country")])
# 
# # root_keys <- unique(xml_list[,"root_key"])
# 
# copyright <- paste('The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:',
#                    'Contains National Statistics data Crown copyright and database right [year]',
#                    'Contains Ordnance Survey data Crown copyright and database right [year]')
# abstract1 <- 'This census data pack provides 2011 Census estimates for the "Key Statistic" and "Quick Statistic" tables within the local authority district'
# abstract2 <- 'at the OA, LSOA and MSOA scale. The estimates are as at census day, 27 March 2011.'
# deviat <- paste('Statistical Disclosure Control',
#                 'In order to protect against disclosure of personal information from the 2011 Census, there has been swapping of records in the Census database between different geographic areas and so some counts will be affected.',
#                 'In the main, the greatest effects will be at the lowest geographies, since the record swapping is targeted towards those households with unusual characteristics in small areas.',
#                 'More details on the ONS Census disclosure control strategy may be found on the Statistical Disclosure Control page on the',
#                 '<a href="http://www.ons.gov.uk/ons/guide-method/census/2011/census-data/2011-census-prospectus/new-developments-for-2011-census-results/statistical-disclosure-control/index.html">ONS web site</a>.')
# 
# keys_df[keys_df$field_key == "deviat",][,"field_value"] <- deviat
# keys_df[keys_df$field_key == "copyright",][,"field_value"] <- copyright
# 
# tag <- "codebook"
# 
# for (row in 1:nrow(lookup)){
#   
#   lookup_row <- lookup[row,]
#   out <- list()
#   
#   keys_df[keys_df$root_key == "stdyDscr" & keys_df$field_key == "titl", ][,"field_value"] <- paste("2011 Census Data Pack:", lookup_row$LAD11NM)
#   keys_df[keys_df$field_key == "nation", ][,"field_value"] <- lookup_row$Country
#   keys_df[keys_df$field_key == "abstract", ][,"field_value"] <- paste(copyright, abstract1, lookup_row$LAD11NM, abstract2, deviat)
#   keys_df[keys_df$field_key == "geogCover", ][,"field_value"] <- lookup_row$LAD11NM
#   
#   for (i in 1:nrow(keys_df)){
#     eval(parse(text=paste("out$",keys_df[i,4],i,"<-keys_df[i,3]",sep="")))
#   }
#   
#   for (i in 1:nrow(keys_df)){
#     path <- paste("out$",substr(keys_df[i,4], 1, nchar(keys_df[i,4]) - nchar(keys_df[i,2]) - 1),sep="")
#     sele_names <- eval(parse(text=paste("names(",path,")",sep="")))
#     idx <- which(sele_names == paste(keys_df[i,2],i,sep=""))
#     eval(parse(text=paste("names(",path,")[idx]<-keys_df[i,2]",sep="")))
#   }
#   
#   out$.attrs <- xml_list$.attrs
#   
#   xml <- listToXml(out,tag)
#   
#   saveXML(xml,paste("~/liverpool/ckan/lad_data/", lookup_row[1], "/", lookup_row[1], ".xml", sep=""))
#   
# }

lad_names <- c("Gateshead", "Northumberland", "Welwyn Hatfield", "St Albans", "Stevenage", "East Hertfordshire")
new_code <- c("E08000037", "E06000057", "E07000241", "E07000240", "E07000243", "E07000242")
changes <- data.frame(lad_names = lad_names, new_code = new_code)


data <- list(grantNo = "ES/L011840/1",
             titl = "",
             AuthEnty = c("Alex Singleton, University of Liverpool", "Michalis Pavlis, University of Liverpool"),
             depositr = "Alex Singleton, University of Liverpool",
             fundAg = "Economic and Social Research Council",
             producer= "ESRC Consumer Data Research Centre",
             copyright = "The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:
             Contains National Statistics data Crown copyright and database right 2015;
             Contains Ordnance Survey data Crown copyright and database right 2015",
             dataCollector = c("Office for National Statistics", "Ordnance Survey"),
             dataSrc = c("Census 2011"),
             topcClas = c("Transport", "Health","Ethnicity", "Energy", "Demographics","Housing"),
             keyword = "",
             abstract = "",
             timePrd = "2011",
             collDate = "27/03/11",
             nation = "",
             geogCover = "",
             geogUnit = c("Output Area", "Lower Super Output Area", "Middle Super Output Area"),
             anlyUnit = c("Area", "Household", "Person"),
             dataKind = c("Count","Sum","Ratio", "Percent"),
             accsPlac = c("Consumer Data Research Centre", "UK Data Service"),
             contact = "data@cdrc.ac.uk",
             relPubl = "",
             serName = "CDRC 2011 Census Data Packs"
)


template <- readLines("/media/michalis/My Passport/ckan/xml_doc.xml")

lookup_lad <- unique(lookup[,c("LAD11CD", "LAD11NM")])
lookup_lad[,1] <- as.character(lookup_lad[,1])
lookup_lad[,2] <- as.character(lookup_lad[,2])
lookup_lad$country <- ifelse(substr(lookup_lad[,1], 1, 1) == "E", "England", "Wales")

for (i in 1:nrow(lookup_lad)){
  
  code <- lookup_lad[i,"LAD11CD"]
  name <- lookup_lad[i,"LAD11NM"]
  
  if (name %in% changes$lad_name){
    new_code_sele <- as.character(changes[changes$lad_name == name, ][,"new_code"])
    data$keyword <- c("Census", "2011", code, new_code_sele)
  } else {
    new_code_sele <- NA
    data$keyword <- c("Census", "2011", code)
  }
  
  data$titl <- paste("CDRC 2011 Census Data Packs for Local Authority District: ", name,  " (", code, ")", sep="")
  data$abstract <- paste("This census data pack provides 2011 Census estimates for the 'Key Statistic' and 'Quick Statistic' tables within the Local Authority District: ",
                         name, " (", code, ")", ifelse(!is.na(new_code_sele), paste(" (", new_code_sele, " in 2015)", sep = ""), ""),
                         " at the Output Area, Lower Super Output Area and Middle Super Output Area scale. The estimates are as at census day, 27 March 2011.",sep="")
  data$nation <- lookup_lad[i,3]
  data$geogCover <- name
  
  readme <- file(paste(path_out, name, "readme.txt", sep="/"))
  writeLines(c(paste("CDRC 2011 Census Geodata pack - ", name, " (", code, ")", ":\n", sep=""),
               "+ Abstract",
               data$abstract,
               "\n",
               "+ Contents",
               "\t - readme.txt: Information about the CDRC Geodata pack",
               "\t - metadata.xml: Metadata",
               "\t - datasets_description.csv: Description of the 2011 Census Key Statistic and Quick Statistic datasets",
               "\t - variables_description.csv: Description of the 2011 Census Key Statistic and Quick Statistic variables",
               paste("\t - tables: Folder containing the OA, LSOA and MSOA 2011 Census data for the Local Authority District: ", name, " (", code, ")", sep=""),
               paste("\t - shapefiles: Folder containing the OA, LSOA and MSOA digital boundaries as shapefiles for the Local Authority District: ", name, " (", code, ")", sep=""),
               "\n",
               "+ Statistical Disclosure Control",
               "In order to protect against disclosure of personal information from the 2011 Census, there has been swapping of records in the Census database between different geographic areas and so some counts will be affected.",
               "In the main, the greatest effects will be at the lowest geographies, since the record swapping is targeted towards those households with unusual characteristics in small areas.",
               "More details on the ONS Census disclosure control strategy may be found on the Statistical Disclosure Control page on the ONS website:",
               "http://www.ons.gov.uk/ons/guide-method/census/2011/census-data/2011-census-prospectus/new-developments-for-2011-census-results/statistical-disclosure-control/index.html","\n",
               "+ Citation and Copyright",
               "The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:",
               "Contains National Statistics data Crown copyright and database right [year]",
               "Contains Ordnance Survey data Crown copyright and database right [year]\n",
               "+ Funding",
               paste("Funded by: Economic and Social Research Council", data$grantNo)),
             readme)
  close(readme)
  
  new_xml <- whisker.render(template, data)
  writeLines(new_xml, paste(getwd(), "/lad_data/", name, "/metadata.xml", sep=""))
}

############################################### zip folders #################################################
# zip
dir.create("england_wales_zip")
out_path <- paste(getwd(), "england_wales_zip", sep="/")
in_path <- paste(getwd(), "lad_data", sep="/")
setwd(in_path)
for (lad in lookup_lad$LAD11NM){
  zip(paste(out_path,"/", lad,".zip",sep=""), files=lad)
}