##########################################################################################################
#                         Output readme.txt, datasets_descriotion.csv, metadata.xml file                 #
#                            for each Combined Authority at the OA, LSOA, MSOA scales                                   #
##########################################################################################################
library(whisker)




data <- list(grantNo = "ES/L011840/1",
             titl = "",
             AuthEnty = c("Alex Singleton, University of Liverpool", "Konstantinos Daras, University of Liverpool"),
             depositr = "Alex Singleton, University of Liverpool",
             fundAg = "Economic and Social Research Council",
             producer= "ESRC Consumer Data Research Centre",
             copyright = "The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:
             Contains National Statistics data Crown copyright and database right 2016;
             Contains Ordnance Survey data Crown copyright and database right 2016",
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

setwd("/media/kd/Data/Dropbox/Repos/rds")

template <- readLines("/media/kd/Data/Dropbox/Repos/rds/m_code/ckan/xml_doc.xml")

cauth_lut <- read.csv(paste(getwd(),"/CombinedAuth/cauth_lut.csv", sep = ""), sep="|")
cauth_ids <- unique(cauth_lut[,c("cauthid", "cauth")])


setwd("/media/kd/Data/temp/CombinedAuth")
fromfile1 <- "/media/kd/Data/Dropbox/Repos/rds/m_code/ckan/datasets_description.csv"
fromfile2 <- "/media/kd/Data/Dropbox/Repos/rds/m_code/ckan/var_desc.csv"
for (i in 1:nrow(cauth_ids)){
  
  code <- paste0("CombAuth", cauth_ids[i,"cauthid"])
  name <- cauth_ids[i,"cauth"]
  
  data$keyword <- c("Census", "2011", code)
  
  data$titl <- paste("CDRC 2011 Census Data Packs for Combined Authority: ", name,  " (", code, ")", sep="")
  data$abstract <- paste("This census data pack provides 2011 Census estimates for the 'Key Statistic' and 'Quick Statistic' tables within the Combined Authority: ",
                         name, " (", code, ")",
                         " at the Output Area, Lower Super Output Area and Middle Super Output Area scale. The estimates are as at census day, 27 March 2011.",sep="")
  data$nation <- "England"
  data$geogCover <- name
  
  readme <- file(paste(getwd(), code, "readme.txt", sep="/"))
  writeLines(c(paste("CDRC 2011 Census Geodata pack - ", name, " (", code, ")", ":\n", sep=""),
               "+ Abstract",
               data$abstract,
               "\n",
               "+ Contents",
               "\t - readme.txt: Information about the CDRC Geodata pack",
               "\t - metadata.xml: Metadata",
               "\t - datasets_description.csv: Description of the 2011 Census Key Statistic and Quick Statistic datasets",
               "\t - variables_description.csv: Description of the 2011 Census Key Statistic and Quick Statistic variables",
               paste("\t - tables: Folder containing the OA, LSOA and MSOA 2011 Census data for the Combined Authority: ", name, " (", code, ")", sep=""),
               paste("\t - shapefiles: Folder containing the OA, LSOA and MSOA digital boundaries as shapefiles for the Combined Authority: ", name, " (", code, ")", sep=""),
               "\n",
               "+ Statistical Disclosure Control",
               "In order to protect against disclosure of personal information from the 2011 Census, there has been swapping of records in the Census database between different geographic areas and so some counts will be affected.",
               "In the main, the greatest effects will be at the lowest geographies, since the record swapping is targeted towards those households with unusual characteristics in small areas.",
               "More details on the ONS Census disclosure control strategy may be found on the Statistical Disclosure Control page on the ONS website:",
               "http://www.ons.gov.uk/ons/guide-method/census/2011/census-data/2011-census-prospectus/new-developments-for-2011-census-results/statistical-disclosure-control/index.html","\n",
               "+ Citation and Copyright",
               "The following attribution statements must be used to acknowledge ONS and OS copyright and source in use of these datasets:",
               "Contains National Statistics data Crown copyright and database right 2016",
               "Contains Ordnance Survey data Crown copyright and database right 2016\n",
               "+ Funding",
               paste("Funded by: Economic and Social Research Council", data$grantNo)),
             readme)
  close(readme)
  
  new_xml <- whisker.render(template, data)
  writeLines(new_xml, paste(getwd(), "/", code, "/metadata.xml", sep=""))
  
  tofile1 <- paste(getwd(), "/", code, "/datasets_description.csv", sep="")
  tofile2 <- paste(getwd(), "/", code, "/variables_description.csv", sep="")
  file.copy(fromfile1, tofile1, overwrite = TRUE, recursive = FALSE, copy.mode = TRUE, copy.date = FALSE)
  file.copy(fromfile2, tofile2, overwrite = TRUE, recursive = FALSE, copy.mode = TRUE, copy.date = FALSE)
  
}


############################################### zip folders #################################################
for (cauth in cauthids$cauthid){
  zip(paste(getwd(),"/CombAuth", cauth,".zip",sep=""), files=paste0("CombAuth",cauth))
}

