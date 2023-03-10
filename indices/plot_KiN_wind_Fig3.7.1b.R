###################################################################################################
#
# Plot seasonal 10 m interpolated nora3 windspeed 1991-2020 for Norway in bokplot style
#
# Used as Fig 3.7.1 right in KiN2100 historical wind chapter
#
# Jan Erik Haugen and Julia Lutz
#
###################################################################################################

#rm(list=ls())

# access libraries
library(ncdf4) 
library(RColorBrewer)

datapath <- c("/lustre/storeB/users/janeh/KiN2100_ny/")
plotpath <- c("~/Documents/results/KiN_misc/")
variable <- "ws10mean"
nc_variable <- "wind_speed_mean"

seasons <- c("DJF","MAM","JJA","SON")
seasonnames <- c("vinter","vår","sommer","høst")

if (variable == "ws10mean") {
  #colors <- c("#F0CCFF","#D990F9","#C54BFB","#A200EA","#690099","#310047")
  colors <- c("#1f78b4", "#6a3d9a", "#33a02c", "#ff7f00")
  #breaks <- c(-100.0,2.0,4.0,6.0,8.0,10.0,100.0)  
  nc_variable <- "wind_speed_mean"
}

# read seasonal data

x <- list()

for (ses in 1:4) {
  
nc <- nc_open(paste0(datapath,"mask_remap_nora3_",variable,"_1991-2020_",seasons[ses],".nc"))
indeks <- ncvar_get(nc, nc_variable)
nc_close(nc) 
  
# data are upside down
indeks <- indeks[,1550:1]
  
x[[ses]] <- indeks
  
min <- min(indeks,na.rm=T); max <- max(indeks,na.rm=T)
cat(paste(variable," ",seasonnames[ses],", min: ",round(min,digits=1), " max: ", round(max,digits=1)," Ntot,Nval: ",length(x[[ses]])," ",length(which(!is.na(x[[ses]]))),"\n",sep=""))
  
}

###################################################################################################

# png(paste0(plotpath,"kin_vind_seasons.png"),width=1800, height=2200, pointsize=20,res=300)
# 
# # left and right border for column each season
# xl <- c(1:4)-0.2
# xr <- c(1:4)+0.2
# # min, max and mean value for all seasons
# yb <- rep(NA,4)
# yt <- rep(NA,4)
# ym <- rep(NA,4)
# for (i in 1:4) {
#   yb[i] <- min(as.numeric(x[[i]]),na.rm=T)
#   yt[i] <- max(as.numeric(x[[i]]),na.rm=T)
#   ym[i] <- mean(as.numeric(x[[i]]),na.rm=T)
# }
# 
# par(mar=c(2,3.5,0.2,0.2))
# # plot without data
# plot(0,0,type="n",xlim=c(0.5,4.5),ylim=c(min(yb),max(yt)),axes=F,
#      xlab="",ylab="")
# axis(1,at=1:4,labels=seasonnames)
# axis(2,las=1)
# mtext(text="Vindhastighet (m/s)",side=2,line=2.5)
# grid()
# box()
# 
# # add data
# 
# # test for cross-check
# #rect(xl-0.05,yb,xr+0.05,yt,col="grey70")
# 
# # loop over season
# for (i in 1:4) {
#   x1 <- xl[i]
#   x2 <- xr[i]
#   # draw rectangles for each color
#   y1 <- yb[i]
#   y2 <- yt[i]
#   rect(x1,y1,x2,y2,col=colors[i])
#   # addmean value
#   lines(c(xl[i]-0.05,xr[i]+0.05),c(ym[i],ym[i]),lwd=5,col="black")
# }
# 
# dev.off()

###################################################################################################

# output plotfile
png(paste0(plotpath,"kin_vind_seasons.png"),width=2000, height=2200, pointsize=20,res=300)

par(mar=c(2,3.5,0.2,0.2))
# plot without data
boxplot(as.vector(x[[1]]),as.vector(x[[2]]),as.vector(x[[3]]),as.vector(x[[4]]),col=colors,axes=FALSE,xlab="",ylab="",boxwex=0.5)
axis(1,at=1:4,labels=seasonnames)
axis(2,las=1)
mtext(text="Vindhastighet (m/s)",side=2,line=2.5)
#grid()
box()

dev.off()
