library(rgdal)
library(rgeos)
library(maptools)
setwd("/media/kd/Data/Dropbox/Repos/rds/NPowerhouse")
NP <- readOGR("data/.", "NPowerhouse")

NP_LIST <- NP@data$NPID

for (i in 1:length(NP_LIST)) {
  
  bf<- sqrt((bbox(NP[NP$NPID == NP_LIST[i],])[2]-bbox(NP[NP$NPID == NP_LIST[i],])[4])^2+(bbox(NP[NP$NPID == NP_LIST[i],])[1]-bbox(NP[NP$NPID == NP_LIST[i],])[3])^2) *.7
  
  
  png(filename = paste0(getwd(),"/icons/NP",NP_LIST[i],".png"),width = 1000, height = 1000, units = "px", pointsize = 12, bg = "transparent",  res = 150)
  plot(gBuffer(SpatialPoints(coordinates(NP[NP$NPID == NP_LIST[i],])),width=bf,byid=TRUE,quadsegs=30),border=NA,col="white")
  plot(NP[NP$NPID == NP_LIST[i],],col="black",add=TRUE)
  dev.off()
  system(paste0("convert ",getwd(),"/icons/NP",paste(NP_LIST[i]),".png -trim ", paste0(getwd(),"/icons/NP",paste(NP_LIST[i]),".png")) ,wait=TRUE,ignore.stdout = TRUE, ignore.stderr = TRUE)
  
}


# Linux image converter
system("mogrify -path icons/sm200/ -resize 200 icons/*.png")

# Mac image converter
# setwd("/media/kd/Data/Dropbox/Repos/rds/CombinedAuth/icons")
# system("sips -Z 200 *.png -o sm200")
