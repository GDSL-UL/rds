library(rgdal)
library(rgeos)
library(maptools)
setwd("/media/kd/Data/Dropbox/Repos/rds/CombinedAuth")
CAUTH <- readOGR("data/.", "CombinedAuth")

CAUTH_LIST <- CAUTH@data$CAUTHID

for (i in 1:length(CAUTH_LIST)) {
  
  bf<- sqrt((bbox(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],])[2]-bbox(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],])[4])^2+(bbox(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],])[1]-bbox(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],])[3])^2) *.7
  
  
  png(filename = paste0(getwd(),"/icons/CompAuth",CAUTH_LIST[i],".png"),width = 1000, height = 1000, units = "px", pointsize = 12, bg = "transparent",  res = 150)
  plot(gBuffer(SpatialPoints(coordinates(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],])),width=bf,byid=TRUE,quadsegs=30),border=NA,col="white")
  plot(CAUTH[CAUTH$CAUTHID == CAUTH_LIST[i],],col="black",add=TRUE)
  dev.off()
  system(paste0("convert ",getwd(),"/icons/CompAuth",paste(CAUTH_LIST[i]),".png -trim ", paste0(getwd(),"/icons/CompAuth",paste(CAUTH_LIST[i]),".png")) ,wait=TRUE,ignore.stdout = TRUE, ignore.stderr = TRUE)
  
}


# Linux image converter
system("mogrify -path icons/sm200/ -resize 200 icons/*.png")

# Mac image converter
# setwd("/media/kd/Data/Dropbox/Repos/rds/CombinedAuth/icons")
# system("sips -Z 200 *.png -o sm200")