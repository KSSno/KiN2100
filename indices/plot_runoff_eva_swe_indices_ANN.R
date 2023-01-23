################################################################
#
# Helga Therese Tilley Tajet, Irene Brox Nilsen og Anita Verpe Dyrrdal
# 2022-2023
#
# Kartplotting for nedbørindekser i KiN2100
#
# Modifisert av IBN 2023-01-23 for å plotte snow, avrenning og fordampning

# Call:
# source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1961, 1990, "runoff", TRUE)
# source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1961, 1990, "swemax", TRUE)
# source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1991, 2020, "swedogn", TRUE)
# source("plot_runoff_evapo_swe_indices_annual.R"); plotting_inds(1991, 2020, "eva", TRUE)
#################################################################

# rm(list=ls())

library(ncdf4)
library(fields)
library(RColorBrewer)
library(plotrix)
library(raster)
library(rgdal)
# hvis de ikke finnes: install.packages("rgdal", repos="http://cran.r-project.org", type="source")

#setEPS()


#input <- "/lustre/storeB/project/KSS/kin2100_2024/Indices/Precipitation/1991-2020/"
#output <- "~/Documents/results/KIN_indicators/"

input <- c("/felles/ibni/KiN/IHA-analyser/hist/")    # fra app05 heter denne /app02-felles/, men bruk 02.
# Kopiert til app-02 fra /hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/pm/hist/results/runoff_1991-2020.nc
# Kopiert til app-02 fra /hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/pm/hist/results/evapo_1991-2020.nc
# Kopiert til app-02 fra /hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/pm/hist/results/swedogn_1991-2020.nc

#output  <- input
maskpath  <- c("/felles/ibni/KiN/temperature_indices/senorge/")

#plotpath <- input



  #################################################################################
############################## Plotting function ####################################
  #################################################################################

plotting_inds  <- function(fra_aar, til_aar, variabel, show_upper_and_lower_limit=FALSE){


   # fra_aar <- 1991; til_aar <- 2020
   # fra_aar <- 1961; til_aar <- 1990
   # variabel <- "runoff"                # "evapo"  # "swe" # "swedogn"
   

print("This function takes 4 arguments: startyear (fra_aar, 1961 or 1991), endyear (til_aar, 1991 or 2020), variable (variabel, 'runoff', 'eva', 'swemax', 'swedogn') and show_upper_and_lower_limit. If you set argument 4 to FALSE, you will not plot the upper and lower numbers on the legend.")


   if (length(args)==0) {             
       print(length(args))
       stop("At least one argument must be supplied ", call.=FALSE)
   } else if (length(args)==1) {
       if (fra_aar==1961 || fra_aar==1991) {
       }else {print("fra_aar må være 1961 eller 1991!")}
   }


   #### READ DATA
    # Norge
    stiogNorgefil <- paste(maskpath, "NorwayMaskOnSeNorgeGrid.nc", sep="")
    nc  <- nc_open(stiogNorgefil)
    #nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/NorwayMaskOnSeNorgeGrid.nc")
    Norge_mask <- ncvar_get(nc,"mask")
    nc_close(nc)
    Norge_mask[is.na(Norge_mask)]=0 # setter alle NA til 0
    # mask <- ncvar_get(nc, "mask")

    # jeg vet ikke hva disse to linjene under gjør... - IBN
    lf <- Norge_mask
    lf[is.na(lf)] <- 0

    # raster_indeks <- raster(indeks) # for å se dimensjoner, brukes ikke videre - IBN

   if (variabel!="eva"){

       fil=paste0(variabel, "_", fra_aar, "-", til_aar, ".nc") # runoff_1991-2020.nc
       # print(fil)
       stiogfil <- paste(input,fil,sep="")
       print(paste0("Input file (stiogfil) = ", input,fil))

       nc <- nc_open(stiogfil)
       #  indeks <- ncvar_get(nc, "tas")      # variabel
       indeks <- ncvar_get(nc, variabel)
       lat <- ncvar_get(nc, "Yc") # "lat")
       lon <- ncvar_get(nc, "Xc") # "lon")
       nc_close(nc) # må den lukkes hver gang? lukker fila, men har hentet ut swe, lat og lon

       nc <- nc_open(fil)
       kart_til_plot <- ncvar_get(nc,variabel)    #Dette funker, men jeg skjønner ikke hvor verdiene ligger. # Fant bare dimensjonene: YC=nc$var$runoff$dim[[1]]$vals Xc=nc$var$runoff$dim[[2]]$vals
       nc_close(nc)
                 #print("maksverdi prior to division =", max(kart_til_plot))
       kart_til_plot <- kart_til_plot/Norge_mask  # hva gjør denne? Fjerner hav og Sverige?
                 #print("maksverdi etter divisjon =", max(kart_til_plot))
       kart_til_plot <- kart_til_plot[,1550:1]

    } else {   # reading in files saved in .txt formats

       seNorge_inds <- read.delim(paste(input, "elevation_norway.txt", sep=""), sep="", header=FALSE)
       print(length(seNorge_inds$V2+1))
       
       fil=paste0("eva_grid_", fra_aar, "_", til_aar, ".txt") # eva_grid_1991_2020.txt NB! Underscore.
       print(fil)
       stiogfil <- paste(input,fil,sep="")
       print(paste0("Input file (stiogfil) = ", input,fil))

       textarray <- read.delim(stiogfil, header=FALSE, sep=" ")
       #print(head(textarray)); 		 	       	     print(tail(textarray))
       #print(length(textarray$V3))		# 1D:     324423  7  -> må gjøres om til 1195  1550
       print(paste("Length = ", length(textarray$V3)))
       
       kart_til_plot <- matrix(rep(NA,1195*1550),nrow=1195)  # Allocate space
      #kart_til_plot[index+1] <- V3
      length(kart_til_plot[seNorge_inds$V2[1:324424]])       # Denne er 324423 lang! 
      kart_til_plot[seNorge_inds$V1[2:324424]] <- textarray$V3[1:324423]    # because it counts from 0
      
      #  kart_til_plot <- rasterFromXYZ(kart_til_plot)   # With the method above, you don't need this one.


        print(dim(kart_til_plot))   
	print(dim(Norge_mask))
	
        kart_til_plot <- kart_til_plot/Norge_mask 
        kart_til_plot <- kart_til_plot[,1550:1]
      

    }   # end if variabel!="eva", fordi fordampningen er lagret som .txt, ikke .nc
   

   # Fargepalett, nedbør

   base_col <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf", "#e6c991","#ccaa66")) #11 colours from blue to brown

   cols <- colorRampPalette(base_col)


   ################################# Runoff/avrenning
   if(variabel=="runoff"){ 

         # These data are skewed, so instead of trying to force the  legend  to cover c(0,100,1000,3000,5000), I plot all values larger than 2500 at 2501.
         kart_til_plot[kart_til_plot>2500] <- 2500


         rand <- c(0, 2500)  # range in the original data: c(0,5000)
         legend_interval <- 500
	 legendunit <- "mm/år"


   ################################# Actual evapotranspiration/fordampning
   # Finner ikke nc-filer med denne variabelen!

     } else if(variabel=="eva"){

    
         rand <- c(0,500) # c(65,225)
         legend_interval <- 100
         legendunit <- "mm/år"

################################# Potential evapotranspiration/ potensiell fordampning
     } else if(variabel=="evapo"){

    	 rand <- c(0,500) # c(65,225)
         legend_interval <- 100
       	 legendunit <- "mm/år"
         print("")
	 print("Note that this option plots the POTENTIAL Evapotranspiration, not the actual EVA.")

   ################################# Snowdays/antall snødager (SD> 1 cm ?)
     } else if(variabel=="swedogn"){

    	 rand <- c(0,360)
	 legend_interval <- 60
       	 legendunit <- "Dager"

         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)

 ################################# Skiing days / antall dager med skiføre (SD>25 cm ?)
     } else if(variabel=="swelangrenn"){

     print("entering swelangrenn")

         rand <- c(0,365)  
         legend_interval <- 60
         legendunit <- "Dager"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)

 ################################# Mountain skiing days /toppturskidager (SD > 50 cm?)
     } else if(variabel=="swetopptur"){

     print("entering swetopptur")

         rand <- c(0,365)  
         legend_interval <- 60
         legendunit <- "Dager"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)


   ################################# Maksimal årlig SWE
     } else if(variabel=="swemax"){

     print("entering swemax")

         # These data are skewed, so instead of trying to force the  legend  to cover a wide range, I plot all values larger than 1200 at 1201.
         # And to get bare ground, I plot all values exactly 0 at -1.
         kart_til_plot[kart_til_plot>1000] <- 1000
         kart_til_plot[kart_til_plot==0] <- -100

         print("entering rand")

         rand <- c(0,1000)  # range in the original data: c(0,1500)
         legend_interval <- 250
         legendunit <- "mm SWE"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)

 ################################# SWE/snøens vannekvivalent
     } else if(variabel=="swe"){

     print("entering swe")

         print("entering rand")

         rand <- c(0,1000)  # range in the original data: c(0,1500)
         legend_interval <- 250
         legendunit <- "mm SWE"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)


 ################################# SWE/snøens vannekvivalent
     } else if(variabel=="swe"){

     print("entering swe")


         print("entering rand")

         rand <- c(0,1000)  # range in the original data: c(0,1500)
         legend_interval <- 250
         legendunit <- "mm SWE"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)


################################# SWE/snøens vannekvivalent
     } else if(variabel=="swe"){

     print("entering swe")
     
	 print("entering rand")
	 
    	 rand <- c(0,1000)  
         legend_interval <- 250
	 legendunit <- "mm SWE"
	 col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
	 #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
	 cols <- colorRampPalette(col_senorge)

	 print("exiting swe")
	 
 ################################# HSM/HSD
     } else if(variabel=="hsm"){

     print("entering hsm")

         rand <- c(0,1000)  
         legend_interval <- 250
         legendunit <- "mm"
         col_senorge <-  rev(c("#000099", "#0019ff", "#0099ff", "#40ccff", "#80ecff", "#d9ffff"))
         #, "#ccf57a"))  # senorge-paletten. Hvis du vil ha grønn, legg inn #ccf57a til høyre.
         cols <- colorRampPalette(col_senorge)


################################# Wet days
     } else if(variabel=="wet_days"){

    	 rand <-  c(65,225)
#	 legend_tics <- c(85,105,125,145,165,185,205)
	 legendunit <- "Dager"
	 #col_new <- rev(c("#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf","#e6c991"))
         cols <- colorRampPalette(col_new)


   ################################# simple_daily_intensity_index, sdii
     } else if(variabel=="simple_daily_intensity_index"){

    	 rand <-  c(0,30)
#	 legend_tics <- c(5,10,15,20,25)
	 legendunit <- "[mm/dag]"
	 #col_new <- rev(c("#3484c9","#1aa0ed","#6abbd8","#b5de9f","#c7e07b","#ffecbf"))
         cols <- colorRampPalette(col_new)


   ################################# 99.7 percentile 
     } else if(variabel=="perc997"){

    	 rand <-  c(0,200)
#	 legend_tics <- c(20,40,60,80,100,120,140,160,180)
	 legendunit <- "mm"
	 #col_new <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf",
         cols <- colorRampPalette(col_new)

   ############################### Days with prec > 20 mm 
     } else if(variabel=="days_gt_20mm"){

    	 rand <-  c(0,100)
	 legend_tics <- c(10,20,30,40,50,60,70,80,90)
	 legendunit <- "Dager"
	 #col_new <- rev(c("#45508a","#406aa8","#3484c9","#1aa0ed","#6abbd8","#9cd6c1","#b5de9f","#c7e07b","#ffecbf","#e6c991"))
         cols <- colorRampPalette(col_new)


   ############################ Consecutive precipitation sum 
     } else if(variabel=="rr_max5day"){

    	 rand <-  c(0,450)
	 legend_tics <- seq(50,400,50)
	 legendunit <- "mm/5 dager"


   }   # end if(variabel)


   if(show_upper_and_lower_limit==TRUE){
   
      legend_tics <- seq(rand[1], rand[2], legend_interval)
      variabel_cols <- cols(length(legend_tics)-1)
      zlimval <- c(min(legend_tics)+legend_interval/2,max(legend_tics)-legend_interval/2) 
      print("You have chosen to show the upper and lower limit on the legend.")
      print("Set argument 4 to FALSE if you want to change it.")
      print(paste(rand[1], " ", rand[2]))
      
   } else {
   
      legend_tics <- seq((rand[1]+legend_interval), (rand[2]-legend_interval), legend_interval)
      variabel_cols <- cols(length(legend_tics)+1)
      #print(legend_tics)
      zlimval <- c(min(legend_tics)-legend_interval/2,max(legend_tics)+legend_interval/2)
      print(paste(rand[1]+legend_interval, " ", rand[2]-legend_interval))
      print("You have chosen to HIDE the upper and lower limit on the legend (argument 4 = FALSE by default).")
      print("")
   }

   print(paste("Legend tics = ", legend_tics))
   print(paste("Number of colors = ", length(variabel_cols)))
   zlim=rand
   print(zlimval[1])
   print(zlimval[2])


   png(paste0(output,"map_30yr_mean_", variabel, "_", fra_aar, "-", til_aar, "_ANN.png"), width=2000, height=2500, pointsize=20,res=300)
	par(mar=c(0.5,0.2,0,0.3))


	image(kart_til_plot, xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=variabel_cols,bty="n", main="")
	contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
	image.plot(kart_til_plot, legend.lab="",legend.line=2.7 ,axis.args=list(tick=FALSE,at=legend_tics),  
           legend.shrink=0.6,legend.only = TRUE,zlim=zlimval,col=variabel_cols,smallplot=c(0.7,0.75,0.1,0.6))
	text(0.77,0.63, legendunit, font=1)
        

   dev.off()

   print(paste0("Plotting is done. Now check your recently generated file ", output, "map_30yr_mean_", variabel, "_", fra_aar, "-", til_aar, "_ANN.png"))

} # End function plotting_inds
