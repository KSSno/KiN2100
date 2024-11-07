library(ncdf4)
library(fields)

#setEPS()

input <- "/lustre/storeB/project/KSS/kin2100_2024/Indices/Precipitation/1991-2020/"
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
##########################################################################################################
##################################### Wet days ###########################################################
##########################################################################################################

nc <- nc_open(paste0(input,"KIN_wet_days_1991-2020_ANN.nc"))
wet_ann_temp <- ncvar_get(nc,"rr")
nc_close(nc)
wet_ann <- wet_ann_temp/mask
wet_ann <- wet_ann[,1550:1]

#cols <- rev(c("#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf","#e6c991"))
rand <- c(65,225)

# postscript(paste0(output,"KIN_wet_days_ANN.eps"), width=7.5, height=7.5, pointsize=15,paper="special")
# par(mar=c(0.5,0.2,0,0.3))
# 
# image(wet_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(8),asp=1,bty="n")
# contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=0.5,col="grey20")
# image.plot(wet_ann,legend.lab="",legend.line=2.7,
#            axis.args=list(tick=FALSE,at=c(85,105,125,145,165,185,205),
#                           labels=c("85","105","125","145","165","185","205")),
#            legend.shrink=0.5,legend.only = TRUE,zlim=c(75,215),col=cols(8),smallplot=c(0.6,0.65,0.1,0.6))
# text(0.72,0.64,"Dager",font=2)
# dev.off()

png(paste0(output,"KIN_wet_days_ANN.png"), width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3))
 
image(wet_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(8),bty="n")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(wet_ann,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=c(85,105,125,145,165,185,205)),
           legend.shrink=0.6,legend.only = TRUE,zlim=c(75,215),col=cols(8),smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,"Dager",font=1)

dev.off()

##########################################################################################################
############################## Simple daily intensity index ##############################################
##########################################################################################################

nc <- nc_open(paste0(input,"KIN_sdii_1991-2020_ANN.nc"))
sdii_temp <- ncvar_get(nc,"sdii")
nc_close(nc)
sdii_ann <- sdii_temp/mask
sdii_ann <- sdii_ann[,1550:1]

#cols <- rev(c("#3484c9","#1aa0ed","#6abbd8","#b5de9f","#c7e07b","#ffecbf"))
rand <- c(0,30)

# postscript(paste0(output,"KIN_sdii_ANN.eps"), width=7.5, height=7.5, pointsize=20)
# par(mar=c(0,0,0,0))
# 
# image(sdii_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(6),asp=1)
# image.plot(sdii_ann,legend.lab="[mm/dag]",legend.line=2.7,axis.args=list(at=c(0,5,10,15,20,25,30)),
#            legend.shrink=0.5,legend.only = TRUE,zlim=c(2.5,27.5),col=cols(6),smallplot=c(0.6,0.65,0.1,0.6))
# dev.off()

png(paste0(output,"KIN_sdii_ANN.png"), width=2000, height=2500, pointsize=22,res=300)
par(mar=c(0.5,0.2,0,0.3))

image(sdii_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(6),bty="n")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(sdii_ann,legend.lab="",legend.line=2.7, axis.args=list(tick=FALSE,at=c(5,10,15,20,25)),
           legend.shrink=0.5,legend.only = TRUE,zlim=c(2.5,27.5),col=cols(6),smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,"mm per dag",font=1)

dev.off()

##########################################################################################################
#################################### 99.7 percentile #####################################################
##########################################################################################################

nc <- nc_open(paste0(input,"KIN_perc997_1991-2020.nc"))
perc_temp <- ncvar_get(nc,"rr")
nc_close(nc)
perc_ann <- perc_temp/mask
perc_ann <- perc_ann[,1550:1]

#cols <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf",
#              "#e6c991"))

rand <- c(0,200)

# postscript(paste0(output,"KIN_perc997_ANN.eps"), width=7.5, height=7.5, pointsize=20)
# par(mar=c(0,0,0,0))
# 
# image(perc_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),asp=1)
# image.plot(perc_ann,legend.lab="[mm]",legend.line=2.7,axis.args=list(at=c(0,20,40,60,80,100,120,140,160,180,200)),
#            legend.shrink=0.5,legend.only = TRUE,zlim=c(10,190),col=cols(10),smallplot=c(0.6,0.65,0.1,0.6))
# dev.off()

png(paste0(output,"KIN_perc997_ANN.png"), width=2000, height=2500, pointsize=22,res=300)
par(mar=c(0.5,0.2,0,0.3))

image(perc_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),bty="n")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(perc_ann,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=c(20,40,60,80,100,120,140,160,180)),
           legend.shrink=0.5,legend.only = TRUE,zlim=c(10,190),col=cols(10),smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,"mm",font=1)

dev.off()

##########################################################################################################
################################## Days with prec > 20 mm ################################################
##########################################################################################################

nc <- nc_open(paste0(input,"KIN_days_gt_20mm_1991-2020_ANN.nc"))
gt20_temp <- ncvar_get(nc,"rr")
nc_close(nc)
gt20_ann <- gt20_temp/mask
gt20_ann <- gt20_ann[,1550:1]

#cols <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf","#e6c991"))

rand <- c(0,100)

# postscript(paste0(output,"KIN_gt20_ANN.eps"), width=7.5, height=7.5, pointsize=20)
# par(mar=c(0,0,0,0))
# 
# image(gt20_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),asp=1)
# image.plot(gt20_ann,legend.lab="[dager]",legend.line=2.7,axis.args=list(at=c(0,10,20,30,40,50,60,70,80,90,100)),
#            legend.shrink=0.5,legend.only = TRUE,zlim=c(5,95),col=cols(10),smallplot=c(0.6,0.65,0.1,0.6))
# dev.off()

png(paste0(output,"KIN_gt20_ANN.png"), width=2000, height=2500, pointsize=22,res=300)
par(mar=c(0.5,0.2,0,0.3))

image(gt20_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),bty="n")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(gt20_ann,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=c(10,20,30,40,50,60,70,80,90)),
           legend.shrink=0.6,legend.only = TRUE,zlim=c(5,95),col=cols(10),smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,"Dager",font=1)

dev.off()


##########################################################################################################
############################### Consecutive precipitation sum ############################################
##########################################################################################################

nc <- nc_open(paste0(input,"KIN_rr_max5day_1991-2020_ANN.nc"))
consec_temp <- ncvar_get(nc,"rr")
nc_close(nc)
consec_ann <- consec_temp/mask
consec_ann <- consec_ann[,1550:1]
consec_ann <- pmin(consec_ann,450)

rand <- c(0,450)

# postscript(paste0(output,"KIN_gt20_ANN.eps"), width=7.5, height=7.5, pointsize=20)
# par(mar=c(0,0,0,0))
# 
# image(gt20_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(10),asp=1)
# image.plot(gt20_ann,legend.lab="[dager]",legend.line=2.7,axis.args=list(at=c(0,10,20,30,40,50,60,70,80,90,100)),
#            legend.shrink=0.5,legend.only = TRUE,zlim=c(5,95),col=cols(10),smallplot=c(0.6,0.65,0.1,0.6))
# dev.off()

png(paste0(output,"KIN_rr_max5day_ANN.png"), width=2000, height=2500, pointsize=22,res=300)
par(mar=c(0.5,0.2,0,0.3))

image(consec_ann,xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=cols(9),bty="n")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
image.plot(consec_ann,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(50,400,50)),
           legend.shrink=0.6,legend.only = TRUE,zlim=c(25,425),col=cols(9),smallplot=c(0.7,0.75,0.1,0.6))
text(0.77,0.63,"mm/5 dager",font=1)

dev.off()