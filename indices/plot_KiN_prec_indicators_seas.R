library(ncdf4)
library(fields)

input <- "/lustre/storeB/project/KSS/kin2100_2024/Indicators/Precipitation/1991-2020/"
output <- "~/Documents/results/KIN_indicators/"

nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/NorwayMaskOnSeNorgeGrid.nc")
mask <- ncvar_get(nc, "mask")
nc_close(nc)
lf <- mask
lf[is.na(lf)] <- 0

base_col <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf",
                  "#e6c991","#ccaa66")) #11 colours from blue to brown
#base_col <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf",
#                  "#e6c991","#ccaa66","#8f6d28","#6e4f12")) #13 colours from blue to brown

cols <- colorRampPalette(base_col)

seas <- c("DJF", "MAM", "JJA", "SON")
##########################################################################################################
##################################### Wet days ###########################################################
##########################################################################################################

for (i in 1:length(seas))
{
  nc <- nc_open(paste0(input,"KIN_wet_days_1991-2020_",seas[i],".nc"))
  wet_temp <- ncvar_get(nc,"rr")
  nc_close(nc)
  wet <- wet_temp/mask
  wet <- wet[,1550:1]

  rand <- c(0,70)

  png(paste0(output,"KIN_wet_days_",seas[i],".png"), width=2000, height=2500, pointsize=20,res=300)
  par(mar=c(0.5,0.2,0,0.3))
  
  image(wet,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(7),bty="n")
  contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
  image.plot(wet,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(10,60,10)),
             legend.shrink=0.6,legend.only = TRUE,zlim=c(5,65),col=cols(7),smallplot=c(0.7,0.75,0.1,0.6))
  text(0.77,0.63,"Dager",font=1)
  
  dev.off()

##########################################################################################################
############################## Simple daily intensity index ##############################################
##########################################################################################################

  nc <- nc_open(paste0(input,"KIN_sdii_1991-2020_",seas[i],".nc"))
  sdii_temp <- ncvar_get(nc,"sdii")
  nc_close(nc)
  sdii <- sdii_temp/mask
  sdii <- sdii[,1550:1]
  
  rand <- c(0,30)
  
  png(paste0(output,"KIN_sdii_",seas[i],".png"), width=2000, height=2500, pointsize=22,res=300)
  par(mar=c(0.5,0.2,0,0.3))
  
  image(sdii,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(6),bty="n")
  contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
  image.plot(sdii,legend.lab="",legend.line=2.7, axis.args=list(tick=FALSE,at=seq(5,25,5)),
             legend.shrink=0.5,legend.only = TRUE,zlim=c(2.5,27.5),col=cols(6),smallplot=c(0.7,0.75,0.1,0.6))
  text(0.77,0.63,"mm per dag",font=1)
  
  dev.off()

##########################################################################################################
#################################### 99.7 percentile #####################################################
##########################################################################################################

  nc <- nc_open(paste0(input,"KIN_perc997_1991-2020_",seas[i],".nc"))
  perc_temp <- ncvar_get(nc,"rr")
  nc_close(nc)
  perc <- perc_temp/mask
  perc <- perc[,1550:1]

  rand <- c(0,200)
  
  png(paste0(output,"KIN_perc997_",seas[i],".png"), width=2000, height=2500, pointsize=22,res=300)
  par(mar=c(0.5,0.2,0,0.3))
  
  image(perc,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),bty="n")
  contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
  image.plot(perc,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(20,180,20)),
             legend.shrink=0.5,legend.only = TRUE,zlim=c(10,190),col=cols(10),smallplot=c(0.7,0.75,0.1,0.6))
  text(0.77,0.63,"mm",font=1)
  
  dev.off()

##########################################################################################################
################################## Days with prec > 20 mm ################################################
##########################################################################################################

  nc <- nc_open(paste0(input,"KIN_days_gt_20mm_1991-2020_",seas[i],".nc"))
  gt20_temp <- ncvar_get(nc,"rr")
  nc_close(nc)
  gt20 <- gt20_temp/mask
  gt20 <- gt20[,1550:1]
  
  rand <- c(0,30)

  png(paste0(output,"KIN_gt20_",seas[i],".png"), width=2000, height=2500, pointsize=22,res=300)
  par(mar=c(0.5,0.2,0,0.3))
  
  image(gt20,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(6),bty="n")
  contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
  image.plot(gt20,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(0,30,5)),
             legend.shrink=0.6,legend.only = TRUE,zlim=c(2.5,27.5),col=cols(6),smallplot=c(0.7,0.75,0.1,0.6))
  text(0.77,0.63,"Dager",font=1)
  
  dev.off()

##########################################################################################################
############################### Consecutive precipitation sum ############################################
##########################################################################################################

  nc <- nc_open(paste0(input,"KIN_rr_max5day_1991-2020_",seas[i],".nc"))
  consec_temp <- ncvar_get(nc,"rr")
  nc_close(nc)
  consec <- consec_temp/mask
  consec <- consec[,1550:1]
  consec <- pmin(consec,450)
  
  rand <- c(0,450)

  png(paste0(output,"KIN_rr_max5day_",seas[i],".png"), width=2000, height=2500, pointsize=22,res=300)
  par(mar=c(0.5,0.2,0,0.3))
  
  image(consec,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(9),bty="n")
  contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
  image.plot(consec,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(50,400,50)),
             legend.shrink=0.6,legend.only = TRUE,zlim=c(25,425),col=cols(9),smallplot=c(0.7,0.75,0.1,0.6))
  text(0.77,0.63,"mm/5 dager",font=1)
  
  dev.off()
  
}