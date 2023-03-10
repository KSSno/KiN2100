###################################################################################################
#
# Plot annual (and seasonal) 10 m interpolated nora3 windspeed 1991-2020 for Norway in KiN2100 style
#
# Used as Fig 3.7.1 left in KiN2100 historical wind chapter
#
# Jan Erik Haugen and Julia Lutz (based on example from Helga Therese Tilley Tajet)
#
###################################################################################################

#rm(list=ls())

# access libraries
library(ncdf4) 
library(fields)
library(RColorBrewer)

# read Norway mask
nc <- nc_open("/lustre/storeB/users/andreasd/PUB/Masks/NorwayMaskOnSeNorgeGrid.nc")
Norway_mask <- ncvar_get(nc,"mask")
nc_close(nc)
# set NAs to 0
Norway_mask[is.na(Norway_mask)] <- 0

# path for input data and output plotfile
datapath <- c("/lustre/storeB/project/KSS/kin2100_2024/Indices/mapfiles_for_plotting/")
plotpath <- c("~/Documents/results/KiN_misc/")

# palette
#colors <- c("#F0CCFF","#D990F9","#C54BFB","#A200EA","#690099","#310047")
colors <- c('#b4dbad','#62c7b7','#30a5d3','#5d5dbc','#5b278d','#310046')

# breaks between colours
breaks <- c(-100.0,2.0,4.0,6.0,8.0,10.0,100.0)  
# colour legend text
intervals <- c(""," 2",""," 4",""," 6",""," 8","","10","")

unit <- "m/s"
nc_variable <- "wind_speed_mean"

# read input windspeed data
nc <- nc_open(paste0(datapath,"mask_remap_nora3_ws10mean_1991-2020_ANN.nc"))
wind <- ncvar_get(nc,nc_variable)
nc_close(nc) 

# data and mask are upside down
wind <- wind[,1550:1]
Norway_mask<- Norway_mask[,1550:1]

# check of min and max
min <- min(wind,na.rm=T); max <- max(wind,na.rm=T)
cat(paste("vind, min: ",round(min,digits=1)," max: ",round(max,digits=1)," ",sep=""))

###################################################################################################

# annual plot

# optional for changing textsize i Rstudio and plotfile
#options(bitmapType="cairo")

# output plotfile
plotfile <- paste(plotpath,"KiN_wind_10m_ANN.png")
png(plotfile,width=2000,height=2500,pointsize=26,res=300) 

par(mar=c(0.5,0.2,0.,0.3))

image(wind,col=colors,breaks=breaks,frame.plot=F,axes=F,zlim=c(0,12))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(wind,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(2,10,2)),
           legend.only=TRUE,col=colors,smallplot=c(0.7,0.75,0.1,0.6),zlim=c(1,11))
text(0.77,0.63,unit,font=1,cex=1.3)

# auxilliary text
#text(0.2,0.90,paste(nc_variable,"ANN",sep=" "),cex=1)
#text(0.2,0.85,paste("min=",round(min,digits=1)," max=",round(max,digits=1),sep=""),cex=1)

dev.off() 

###################################################################################################

# repeat for seasonal plots

seas <- c("DJF","MAM","JJA","SON")

for (i in 1:length(seas)) {
 
nc <- nc_open(paste0(datapath,"mask_remap_nora3_ws10mean_1991-2020_",seas[i],".nc"))
wind <- ncvar_get(nc,nc_variable)
nc_close(nc)

wind <- wind[,1550:1]
  
min <- min(wind,na.rm=T); max <- max(wind,na.rm=T)
cat(paste("vind, min: ",round(min,digits=1)," max: ",round(max,digits=1)," ",sep=""))
  
png(paste0(plotpath,"KIN_wind_10m_",seas[i],".png"),width=2000,height=2500,pointsize=26,res=300)

par(mar=c(0.5,0.2,0,0.3))
  
image(wind,xlab="",ylab="",xaxt="n",yaxt="n",zlim=c(0,12),col=colors,bty="n")
contour(Norway_mask,add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(wind,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(2,10,2)),legend.only = TRUE,
           zlim=c(1,11),col=colors,smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,unit,font=1,cex=1.3)
  
dev.off()

}

