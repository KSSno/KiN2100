source("/data06/shh/KiN/scripts/plot/raster_legend_triangle_end.r")

#################################################################

# rm(list=ls())

library(ncdf4)
library(fields)
library(RColorBrewer)
library(plotrix)
library(raster)
library(rgdal)
# hvis de ikke finnes: install.packages("rgdal", repos="http://cran.r-project.org", type="source")

input <- c("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results")    # fra app05 heter denne /app02-felles/, men bruk app02

output  <- input
#maskpath  <- c("/app02-felles/ibni/KiN/temperature_indices/senorge/")
 maskpath  <- c("/hdata/hmdata/KiN2100/misc") # fra app-02

plotpath <- "/data06/shh/KiN/results"


  #################################################################################
############################## Plotting function ####################################
  #################################################################################

plotting_inds_absolute_endering  <- function(fra_aar, til_aar, variabel_inn, rcp, season, var_col, total_legend_length){

#fra_aar <- 2071
#til_aar <- 2100
#variabel_inn <- "hsd"    #run   eva   swe_max "swe_ndogn_1cm","swe_ndogn_langrenn","swe_ndogn_topptur","hsd"
#rcp <- "rcp26"
#season <- "Sommer"   #c("År","Vinter","Vår","Sommer","Høst")
#var_col <- 3

nc <- nc_open("/hdata/hmdata/KiN2100/misc/kss2023_mask1km_norway.nc4")
#nc <- nc_open("/felles/ibni/KiN/temperature_indices/senorge/NorwayMaskOnSeNorgeGrid.nc")
Norway_mask <- ncvar_get(nc,"mask")
nc_close(nc)

var_in <- read.table(paste(input, "/", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, "_ensemble_change_absolute.txt", sep=""), header=FALSE)

                   til_plot <- as.vector(Norway_mask)
                 if(variabel_inn=="hsd") {
                 til_plot[which(til_plot==1)] <- -var_in[,var_col]
                  } else {
		til_plot[which(til_plot==1)] <- var_in[,var_col]
                   }
		kart_til_plot <- matrix(til_plot,ncol=1550)
		kart_til_plot<- kart_til_plot[,1550:1] 
                Norway_mask<- Norway_mask[,1550:1] 
                Norway_mask[is.na(Norway_mask)]=0       
         #  kart_til_plot <- rasterFromXYZ(var_in)  
             min_var <- min(til_plot,na.rm=T); max_var <- max(til_plot,na.rm=T)
          quantile(til_plot,c(0.1,0.25,0.5,0.75,0.9), na.rm=T)


      colors <- c("#8c510a","#bf812d","#dfc27d","#f6e8c3","#f5f5f5","#c7eae5","#80cdc1","#35978f","#01665e") #11 colours from blue to brown
      
      intervals <- c(-400,-200,-100,-50,50,100,200,400)

      legendunit <- "mm"


    ############################################### plotting
png(paste(plotpath, "/map_30yr_ensemble_mean_absolute_change_", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, ".png", sep=""),width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3)) 

######test whether "image" gives the right color if the min and max don't fit the intervals
       sii <-1
       eii <- length(intervals)

      for(i in 1:length(intervals)) {
       
      if (min_var>=intervals[i]) sii<- sii+1
      if(max_var<=intervals[length(intervals)-i+1]) eii <- eii-1
       }

      breaks <- c(min_var, intervals[sii:eii],max_var)
      colors_breaks <- colors[sii:(eii+1)]
      print(intervals)
      print(breaks)
      print(colors_breaks)

intervals_legend <- add_space(as.character(intervals), total_legend_length, side="left")

if(min_var==intervals[1]) { 
image(kart_til_plot,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var,max_var))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_up(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")

} else if(max_var==intervals[length(intervals)]) { 
image(kart_til_plot,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var,max_var))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_bottom(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")

} else {
image(kart_til_plot,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var,max_var))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_both(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")
}

#color.legend(0.65,0.1,0.7,0.5,legend=intervals,rect.col=colors,gradient="y",align="rb")   # if only rectangles are preferred.

text(0.7,0.53,legendunit,cex=1)

dev.off()

   print(paste0("Plotting is done. Now check your recently generated file ", plotpath, "/map_30yr_ensemble_mean_change_", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, ".png", sep=""))

} # End function plotting_inds

###############################
###################runoff map based plotting
################################
plotting_inds_runoffmap_endering  <- function(fra_aar, til_aar, variabel_inn, rcp, season, var_col, total_legend_length){

#fra_aar <- 2071
#til_aar <- 2100
#variabel_inn <- "run"    #run   eva   swe_max "swe_ndogn_1cm","swe_ndogn_langrenn","swe_ndogn_topptur","hsd"
#rcp <- "rcp45"
#season <- "Høst"   #c("År","Vinter","Vår","Sommer","Høst")
#var_col <- 3
if(season=="År") season2 <- "annual"
if(season=="Vinter") season2 <- "winter"
if(season=="Vår") season2 <- "spring"
if(season=="Sommer") season2 <- "summmer"
if(season=="Høst") season2 <- "autumn"

nc <- nc_open("/hdata/hmdata/KiN2100/misc/kss2023_mask1km_norway.nc4")
#nc <- nc_open("/felles/ibni/KiN/temperature_indices/senorge/NorwayMaskOnSeNorgeGrid.nc")
Norway_mask <- ncvar_get(nc,"mask")
nc_close(nc)

var_in <- read.table(paste(input, "/", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, "_ensemble_change.txt", sep=""), header=FALSE)

                   til_plot <- as.vector(Norway_mask)
                 if(variabel_inn=="hsd") {
                 til_plot[which(til_plot==1)] <- -var_in[,var_col]
                  } else {
		til_plot[which(til_plot==1)] <- var_in[,var_col]
                   }
		kart_til_plot <- matrix(til_plot,ncol=1550)
		kart_til_plot<- kart_til_plot[,1550:1] 
                Norway_mask<- Norway_mask[,1550:1] 
                Norway_mask[is.na(Norway_mask)]=0       
         #  kart_til_plot <- rasterFromXYZ(var_in)  

runoffmap <- read.table(paste("/hdata/fou/Avrenningskart/WASMOD/endelige_resultater/Final_Version_5/corr_maps_ver5_LTMean/LTMean_Runoff_",
season2,"_corrected.asc",sep=""),skip=6,header=F)

runoffmap [runoffmap <0] <- NA
min_var_r <- min(runoffmap,na.rm=T)
max_var_r<- max(runoffmap,na.rm=T)
runoff_plot <- as.matrix(runoffmap)
kart_runoff_plot <- t(runoff_plot)
kart_runoff_plot <- kart_runoff_plot[,1550:1]

mask_til_plot <- as.vector(Norway_mask)
kart_runoff_plot_v <- as.vector(kart_runoff_plot)
kart_til_plot_v <- as.vector(kart_til_plot)

kart_runoff_plot_v[which(mask_til_plot==0)] <- NA
kart_til_plot_v_endering <- kart_runoff_plot_v*(1+kart_til_plot_v/100)

kart_runoff_plot_final <- matrix(kart_runoff_plot_v,ncol=1550)
kart_til_plot_final <- matrix(kart_til_plot_v_endering,ncol=1550)

  min_var <- min(kart_til_plot_v_endering,na.rm=T); max_var <- max(kart_til_plot_v_endering,na.rm=T)
          quantile(kart_til_plot_v_endering,c(0.1,0.25,0.5,0.75,0.9), na.rm=T)


########plot runoffmap 
      
     if(season2=="annual") {
     colors <- c("#ccaa66","#e6c991","#ffecbf","#c7e07b","#b5de9f","#9cd6c1","#6abbd8","#1aa0ed","#3484c9") #9 colours from blue to brown
     intervals <- c(500,1000,1500,2000,2500,3000,3500,4000)
      } else {
     intervals <- c(50,100,150,200,250,300,350,400,500,1000,1500)
     colors <- c("#8f6d28","#ccaa66","#e6c991","#ffecbf","#c7e07b","#b5de9f","#9cd6c1","#6abbd8","#1aa0ed","#3484c9","#406aa8","#45508a") #11 colours from blue to brown
      }

      legendunit <- "mm"

       sii <-1
       eii <- length(intervals)

      for(i in 1:length(intervals)) {
       
      if (min_var_r>=intervals[i]) sii<- sii+1
      if(max_var_r<=intervals[length(intervals)-i+1]) eii <- eii-1
       }

      breaks <- c(min_var_r, intervals[sii:eii],max_var_r)
      colors_breaks <- colors[sii:(eii+1)]
      print(intervals)
      print(breaks)
      print(colors_breaks)

png(paste(plotpath, "/map_30yr_ensemble_mean_runoffmap_norway_1991_2020_",
                     season, ".png", sep=""),width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3)) 

intervals_legend <- add_space(as.character(intervals), total_legend_length, side="left")


image(kart_runoff_plot_final,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var_r,max_var_r))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_both(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")
text(0.7,0.53,legendunit,cex=1)

dev.off()


##### plot changes
     colors <- c("#8f6d28","#ccaa66","#e6c991","#ffecbf","#c7e07b","#b5de9f","#9cd6c1","#6abbd8","#1aa0ed","#3484c9","#406aa8","#45508a") #11 colours from blue to brown
      
      intervals <- c(50,100,150,200,250,300,350,400,500,1000,1500)

      legendunit <- "mm"


    ############################################### plotting
png(paste(plotpath, "/map_30yr_ensemble_mean_absolute_change_runoffmap_", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, ".png", sep=""),width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3)) 

######test whether "image" gives the right color if the min and max don't fit the intervals
       sii <-1
       eii <- length(intervals)

      for(i in 1:length(intervals)) {
       
      if (min_var>=intervals[i]) sii<- sii+1
      if(max_var<=intervals[length(intervals)-i+1]) eii <- eii-1
       }

      breaks <- c(min_var, intervals[sii:eii],max_var)
      colors_breaks <- colors[sii:(eii+1)]
      print(intervals)
      print(breaks)
      print(colors_breaks)

intervals_legend <- add_space(as.character(intervals), total_legend_length, side="left")

if(min_var==intervals[1]) { 
image(kart_til_plot_final,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var_r,max_var_r))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_up(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")

} else if(max_var==intervals[length(intervals)]) { 
image(kart_til_plot_final,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var,max_var))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_bottom(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")

} else {
image(kart_til_plot_final,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var,max_var))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_both(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")
}

#color.legend(0.65,0.1,0.7,0.5,legend=intervals,rect.col=colors,gradient="y",align="rb")   # if only rectangles are preferred.

text(0.7,0.53,legendunit,cex=1)

dev.off()

   print(paste0("Plotting is done. Now check your recently generated file ", plotpath, "/map_30yr_ensemble_mean_change_", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
                     season, ".png", sep=""))

} # End function plotting_inds


###################runoff map based plotting
################################
plotting_inds_runoffmap  <- function(fra_aar, til_aar, variabel_inn, rcp, season, var_col, total_legend_length){

nc <- nc_open("/hdata/hmdata/KiN2100/misc/kss2023_mask1km_norway.nc4")
#nc <- nc_open("/felles/ibni/KiN/temperature_indices/senorge/NorwayMaskOnSeNorgeGrid.nc")
Norway_mask <- ncvar_get(nc,"mask")
nc_close(nc)

Norway_mask<- Norway_mask[,1550:1] 
Norway_mask[is.na(Norway_mask)]=0   

runoffmap <- read.table(paste("/hdata/fou/Avrenningskart/WASMOD/endelige_resultater/Final_Version_5/corr_maps_ver5_LTMean/LTMean_Runoff_",
season,"_corrected.asc",sep=""),skip=6,header=F)

runoffmap [runoffmap <0] <- NA
min_var_r <- min(runoffmap,na.rm=T)
max_var_r<- max(runoffmap,na.rm=T)
runoff_plot <- as.matrix(runoffmap)
kart_runoff_plot <- t(runoff_plot)
kart_runoff_plot <- kart_runoff_plot[,1550:1]

mask_til_plot <- as.vector(Norway_mask)
kart_runoff_plot_v <- as.vector(kart_runoff_plot)

kart_runoff_plot_v[which(mask_til_plot==0)] <- NA
kart_runoff_plot_final <- matrix(kart_runoff_plot_v,ncol=1550)


########plot runoffmap 
      
     if(season=="annual") {
     colors <- c("#e6c991","#ffecbf","#c7e07b","#b5de9f","#9cd6c1","#6abbd8","#1aa0ed","#3484c9" ,"#406aa8") #9 colours from blue to brown
     intervals <- c(500,1000,1500,2000,2500,3000,3500,4000)
      } else {
     intervals <- c(50,100,150,200,250,300,350,400,500,1000,1500)
     colors <- c("#8f6d28","#ccaa66","#e6c991","#ffecbf","#c7e07b","#b5de9f","#9cd6c1","#6abbd8","#1aa0ed","#3484c9","#406aa8","#45508a") #11 colours from blue to brown
      }

      legendunit <- "mm"

       sii <-1
       eii <- length(intervals)

      for(i in 1:length(intervals)) {
       
      if (min_var_r>=intervals[i]) sii<- sii+1
      if(max_var_r<=intervals[length(intervals)-i+1]) eii <- eii-1
       }

      breaks <- c(min_var_r, intervals[sii:eii],max_var_r)
      colors_breaks <- colors[sii:(eii+1)]
      print(intervals)
      print(breaks)
      print(colors_breaks)

png(paste(plotpath, "/map_30yr_ensemble_mean_runoffmap_norway_",fra_aar,"_",til_aar,"_",
                     season, ".png", sep=""),width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3)) 

intervals_legend <- add_space(as.character(intervals), total_legend_length, side="left")


image(kart_runoff_plot_final,col=colors_breaks,breaks=breaks,frame.plot=F,axes=F,zlim=c(min_var_r,max_var_r))
contour(Norway_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend_triangle_both(0.65,0.1,0.7,0.5,legend=intervals_legend,rect.col=colors,gradient="y",align="rb")
text(0.7,0.53,legendunit,cex=1)

dev.off()



} # End function plotting_inds



