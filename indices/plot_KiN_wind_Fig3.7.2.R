###################################################################################################
#
# Plot trendmap of 10 m interpolated nora3 windspeed 1991-2020 for Norway in KiN2100 style
#
# Used as Fig 3.7.2 in KiN2100 historical wind chapter
#
# Julia Lutz
#
###################################################################################################

# access libriaries
library(ncdf4)
library(fields)
library(RColorBrewer)

#setEPS()

# path for input data and output plotfile
input <- "/lustre/storeB/project/KSS/kin2100_2024/Indices/mapfiles_for_plotting/"
output <- "~/Documents/results/KiN_misc/"

# read Norway mask, data are upside down
nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/NorwayMaskOnSeNorgeGrid.nc")
mask <- ncvar_get(nc, "mask")
nc_close(nc)
lf <- mask[,1550:1]
lf[is.na(lf)] <- 0

# colours
base_col <- rev(brewer.pal("RdBu",n=10))
cols <- colorRampPalette(base_col)

# grey colour
#base_grey <- brewer.pal("Greys",n=9)
#cols_grey <- colorRampPalette(base_grey)(10)
#cols_grey <- c("#FFFFFF99","#F1F1F199","#DEDEDE99","#C6C6C699","#A7A7A799","#86868699","#68686899","#48484899",
#               "#20202099","#00000099")
cols_grey <- c("#bdbdbd99","#52525299")

# read input, data are upside down

nc <- nc_open(paste0(input,"nora3_ws10mean_yr-lcc_1991-2020_remap.nc"))
wind_mean <- ncvar_get(nc,"wind_speed_mean")
nc_close(nc)
wind_mean <- wind_mean[,1550:1]

nc <- nc_open(paste0(input,"nora3_ws10mean_yr-lcc_trendTS_1991-2020_remap.nc"))
wind_trend <- ncvar_get(nc,"b")
nc_close(nc)
wind_trend <- wind_trend[,1550:1]

nc <- nc_open(paste0(input,"nora3_ws10mean_yr-lcc_trendMK_1991-2020_remap.nc"))
wind_p <- ncvar_get(nc,"p_value")
nc_close(nc)
wind_p <- wind_p[,1550:1]
test <- which(wind_p > 0.2, arr.ind=TRUE)

test_mod <- wind_p
test_mod[test_mod>0.2] <- NA
test_mod[!is.na(test_mod)] <- 1

# trend
diff_rel <- wind_trend/wind_mean * 10 * 100

###################################################################################################

# output plotfile
png(paste0(output,"KIN_vind_trend_signi_2grey.png"), width=2000, height=2500, pointsize=20, res=300)

par(mar=c(0.5,0.2,0,0.3))

#image(diff_rel,xlab="",ylab="",xaxt="n",yaxt="n",zlim=c(-5,5),col=base_col,bty="n")
image(diff_rel,xlab="",ylab="",xaxt="n",yaxt="n",zlim=c(-5,5),col=cols_grey,bty="n")
image(diff_rel*test_mod,xlab="",ylab="",xaxt="n",yaxt="n",zlim=c(-5,5),col=base_col,bty="n",add=TRUE)
contour(lf,add=T,levels=0.5,drawlabels=FALSE,lwd=1,col="grey20")
#points(as.numeric(test[,1])/1195,as.numeric(test[,2])/1550,pch="/",col="#ffffff10",cex=0.3)
#contour(wind_p,add=T,levels=0.2,drawlabels=FALSE,lwd=1,col="yellow")
#polygon(c(rev(as.numeric(test[,1])/1195),as.numeric(test[,1])/1195),c(rev(as.numeric(test[,2])/1550),as.numeric(test[,2])/1550),
#        col="yellow",density=5,angle=45)
#image.plot(diff_rel,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(-4,4,1)),
#           legend.shrink=0.6,legend.only=TRUE,zlim=c(-4.5,4.5),col=base_col,smallplot=c(0.7,0.75,0.06,0.6))
image.plot(diff_rel,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=seq(-4,4,1)),
           legend.shrink=0.6,legend.only=TRUE,zlim=c(-4.5,4.5),col=base_col,smallplot=c(0.8,0.85,0.06,0.6))
image.plot(diff_rel,legend.lab="",legend.line=2.7,axis.args=list(tick=FALSE,at=c(-2.5,2.5),lab=c("< 0","> 0")),
           legend.shrink=0.6,legend.only=TRUE,zlim=c(-2.5,2.5),col=cols_grey,smallplot=c(0.58,0.63,0.06,0.6))
text(0.74,0.63,"% per dekade",font=1,cex=1.2)

dev.off()

