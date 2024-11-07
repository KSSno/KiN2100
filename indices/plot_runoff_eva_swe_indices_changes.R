################################################################
#
# Helga Therese Tilley Tajet, Irene Brox Nilsen og Anita Verpe Dyrrdal
# 2022-2023
#
# Kartplotting for hydrologiske indekser i KiN2100
#
# Modifisert av IBN 2023-06-05 for å plotte tørke
# Modifisert av IBN 2023-01-23 for å plotte avrenning, fordampning og SWE

# Call:
# Run from app02 (it has ncdf4 installed)
# cd /felles/ibni/KiN/IHA-analyser/hist
# R
# source("plot_runoff_eva_swe_indices_ANN_with_filepaths.R"); plotting_inds(1961, 2020, "droughtDurTrend", TRUE)
# source("plot_runoff_eva_swe_indices_ANN_with_filepaths.R"); plotting_inds(1991, 2020, "droughtDurTrend", TRUE)
## source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1961, 1990, "runoff", TRUE)
## source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1961, 1990, "swemax", TRUE)
## source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1991, 2020, "swedogn", TRUE)
## source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1991, 2020, "eva", TRUE)
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

plotpath <- "/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results"


  #################################################################################
############################## Plotting function ####################################
  #################################################################################

plotting_inds_relative_endering  <- function(fra_aar, til_aar, variabel_inn, rcp, season, season2,var_col, total_legend_length){

#fra_aar <- 2071
#til_aar <- 2100
#variabel_inn <- "hsd"    #run   eva   swe_max "swe_ndogn_1cm","swe_ndogn_langrenn","swe_ndogn_topptur","hsd"
#rcp <- "rcp26"
#season <- "Sommer"   #c("�r","Vinter","V�r","Sommer","H�st")
#var_col <- 3
print(season)

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
             min_var <- min(til_plot,na.rm=T); max_var <- max(til_plot,na.rm=T)
          quantile(til_plot,c(0.1,0.25,0.5,0.75,0.9), na.rm=T)

################################# Runoff/avrenning
   if(variabel_inn=="run"){ 

      if(season2=="annual") {
      colors <- c("#bf812d","#dfc27d","#f6e8c3","#f5f5f5","#c7eae5","#80cdc1","#35978f","#01665e") #11 colours from blue to brown
      intervals <- c(-10, -5,-1,1,5,10,15)
      } else {
      colors <- c("#8c510a","#bf812d","#dfc27d","#f6e8c3","#f5f5f5","#c7eae5","#80cdc1","#35978f","#01665e") #11 colours from blue to brown
      
      intervals <- c(-75,-35,-15,-5,5,15,35,75)
      }

      legendunit <- "Prosent"

   ################################# Actual evapotranspiration/fordampning

     } else if(variabel_inn=="eva"){

    
      colors <- c("#c7eae5","#80cdc1","#35978f","#01665e", "#003c30") 
      intervals <- c( 10,20,30,40)
     
      #intervals <- c(" 0 til 10"," 10 til 20",
      #	  " 20 til 30"," 30 til 40", " >40")
      legendunit <- "Prosent"

   ################################# Snowdays/antall snødager (SD> 1 cm ?)
     } else if(variabel_inn=="swe_ndogn_1cm"){

         legendunit <- "Dager"

         colors <- c("#01665E","#35978F","#80CDC1","#C7EAE5","#f5f5f5") 
      intervals <- c(-90,-60,-30,0)
      #intervals <- c(" -90"," -60"," -30"," -1", " 0")
      


 ################################# Skiing days / antall dager med skiføre (SD>25 cm ?)
     } else if(variabel_inn=="swe_ndogn_langrenn"){

       legendunit <- "Dager"
      colors <- c("#01665E","#35978F","#80CDC1","#C7EAE5","#f5f5f5") 
      intervals <- c( -90,-60,-30,0)
      #intervals <- c(""," -90",""," -60",""," -30",""," 0", "")
      
 ################################# Mountain skiing days /toppturskidager (SD > 50 cm?)
     } else if(variabel_inn=="swe_ndogn_topptur"){

       legendunit <- "Dager"
      colors <- c("#01665E","#35978F","#80CDC1","#C7EAE5","#f5f5f5")  
      intervals <- c(-90,-60,-30,0)
      #intervals <- c(""," -90",""," -60",""," -30",""," 0", "")
      


   ################################# Maksimal årlig SWE
     } else if(variabel_inn=="swe_max"){

      colors <- rev(c("#40ccff","#ccf57a","#b8d175","#98ad5f","#308201","#255c36","#000000") )
      intervals <- c(-500,-300,-200,-100,-50,0)
      #intervals <- c(""," -500",""," -400",""," -300",""," -200",""," -100",""," 0","")   # "" make the labels at the intersection of the boxes rather than in the center
      legendunit <- "SWE (mm)"

	 
 ################################# HSM/HSD
     } else if(variabel_inn=="hsd"){

       legendunit <- "mm"
      colors <- c("#a66b1c","#f49857","#FFCC19","#f5f5f5","#199FED") 
      intervals <- c( -25,-15,-5,5)
      #intervals <- c(""," -25",""," -15",""," -5",""," 5", "")

   }   # end if(variabel_inn)



############################################### plotting
png(paste(plotpath, "/map_30yr_ensemble_mean_change_", variabel_inn, "_", rcp, "_norway_", fra_aar, "_", til_aar,"_",
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
                     season2, ".png", sep=""))

} # End function plotting_inds
