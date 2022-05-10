################################################################
#
# Helga Therese Tilley Tajet, Irene Brox Nilsen og Anita Verpe Dyrrdal
# mai 2022
# 
# Plotting av kart for KiN2100 temperaturindikatorer
#
# aarstid = "annual", "winter", "summer", "autumn" eller "spring"
# variabel = "dzc", "heatwave", "summerdays", "tropicalnights", "frostdays"
#
#################################################################

rm(list=ls())

library(ncdf4) 
library(rgdal)
library(fields)
library(RColorBrewer)
library(plotrix)
library(raster)

sti <- c("/lustre/storeB/project/KSS/HelgaTherese/KiN2100/temperaturindikatorer/")
plotpath <- c("/lustre/storeB/project/KSS/kin2100_2024/Indicators/Temperature/Figs/")

plot.tempindex <- function(fra_aar = 1991, til_aar = 2020, aarstid = "annual", variabel = "heatwave") {


if(variabel=="dzc"){
  colors = c("#01665E", "#35978F", "#C7EAE5", "#F6E8C3", "#BF812D", "#8C510A")
  breaks <- c(0,10,20,30,40,50,60)   # default er sesongverdier. Hvis du velger "annual", overskrives disse med årsverdier.
  intervals <- c("0-10"," 10-20"," 20-30"," 30-40"," 40-50"," 50-60")
  
  if(aarstid=="winter"){aarstidsnavn = "vinter"
  }else if(aarstid=="spring"){aarstidsnavn = "vår"     
  }else if(aarstid=="summer"){aarstidsnavn = "sommer"
  }else if(aarstid=="autumn"){aarstidsnavn = "høst"
  
  }else if(aarstid=="annual"){aarstidsnavn = "år"
  
  breaks <- c(0,50,75,100,125,150,200)
  intervals <- c("< 50"," 50-75"," 75-100"," 100-125"," 125-150",">150")
  }
  
  variabelnavn=paste("DZC ",aarstidsnavn) #"Dager med nullgraderspasseringer"
  enhet <- paste("Dager per",aarstidsnavn)
}      

if(variabel=="heatwave"){
  colors <- c("white","peachpuff","rosybrown2","darkorange1","orangered","red","red3","purple","purple4")
  #Legende som intervaller
  #breaks <- c(0,0.1,0.3,0.5,0.8,1,1.2,1.5,2,2.5)  
  #intervals <- c(" 0"," 0,1 - 0,29"," 0,3 - 0,49"," 0,5 - 0,79"," 0,8 - 0,99"," 1,0 - 1,19"," 1,2 - 1,49"," 1,5 - 1,99"," ≥ 2,0") # intervaller
  # Legende i overgangen mellom fargene
  breaks <- c(0,0,0.2999,0.4999,0.79,0.99,1.19,1.49,1.999,3)  
  intervals <- c(""," 0,1",""," 0,3",""," 0,5 ",""," 0,8 ",""," 1,0",""," 1,2 ",""," 1,5 ",""," 2,0","")
  
  if(aarstid=="annual"){aarstidsnavn <- "hele året"}
  
  variabelnavn=paste("Hetebølge ",aarstidsnavn) #"Hetebølge "
  enhet <- paste("Hendelser per",aarstidsnavn)
}

if(variabel=="summerdays"){
  
  colors <- c("palegoldenrod","darkgoldenrod1","darkorange","orangered","red","red3")
  #Legende som intervaller
  breaks <- c(0,4,8,12,16,20,23)
  intervals <- c(" 0-4"," 4-8"," 8-12"," 12-16"," 16-20"," 20-23")#10-12","12-14","14-16","16-23")
  
  if(aarstid=="annual"){aarstidsnavn <- "hele året"}
  
  variabelnavn=paste("Sommerdager",aarstidsnavn)
  enhet <- paste("Dager per",aarstidsnavn)
}

if(variabel=="tropicalnights"){
  colors <- c("white","tan2","tomato2","tomato3","tomato4")  
  #Legende som intervaller
  breaks <- c(0,0.01,0.1,0.2,0.3,0.5)  
  intervals <- c(" 0"," 0,01-0,1"," 0,1-0,2"," 0,2-0,3"," 0,3-0,5")
  
  if(aarstid=="annual"){aarstidsnavn <- "hele året"}
  
  variabelnavn=paste("Tropenetter ",aarstidsnavn) 
  enhet <- paste("Antall per",aarstidsnavn)
}

if(variabel=="frostdays"){
  
  colors <- c("slategray1","steelblue1","steelblue2","steelblue3","royalblue","royalblue3","royalblue4")
  #Legende som intervaller
  breaks <- c(0,50,100,150,200,250,300,332)
  intervals <- c(" < 50"," <50-100]"," 100-150"," 150-200"," 200-250"," 250-300", " 300-350")#10-12","12-14","14-16","16-23")
  
  if(aarstid=="annual"){aarstidsnavn <- "hele året"}
  
  variabelnavn=paste("Frostdager",aarstidsnavn) 
  enhet <- paste("Dager per",aarstidsnavn)
}

variabelogSesong = paste(variabel,"_", aarstid, sep="") 

###### Input files ######
fil <- paste("sn2018v2005_hist_none_none_norway_1km_",variabel,"_",aarstid,"-mean_",fra_aar,"-",til_aar,".nc4",sep="")
stiogfil <- paste(sti,fil,sep="")

nc <- nc_open(stiogfil)
indeks <- ncvar_get(nc, variabel)
lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon")
nc_close(nc) 

# Norge 
nc <- nc_open("/lustre/storeB/users/andreasd/PUB/Masks/NorwayMaskOnSeNorgeGrid.nc")
Norge_mask <- ncvar_get(nc,"mask")
nc_close(nc)
Norge_mask[is.na(Norge_mask)]=0 # setter alle NA til 0

# må snu kartet, det er opp ned
indeks <- indeks[,1550:1]
Norge_mask<- Norge_mask[,1550:1]

# -------------------- Sjekke variabelen ------------------------------------------------------------

cat(paste(variabelnavn, ", min: ",round(min(indeks,na.rm=T),digits=1), " max: ", round(max(indeks,na.rm=T),digits=1),sep=""))

# -------------------- PLOT -------------------------------------------------------------------------

options(bitmapType="cairo") # for å få endre på tekst str. i Rstudio og for lagring av plot

plotfile <- paste(plotpath,variabelogSesong,"_",fra_aar,"-",til_aar,sep="")
png(paste(plotfile,".png",sep=""),width=900,height=1100,pointsize=25) 
#pdf(paste(plotfile,".pdf",sep=""),width=9,height=11) 

image(indeks,col=colors,breaks=breaks,frame.plot=F,axes=F)
contour(Norge_mask,add=T,levels = 0.5 ,drawlabels = FALSE,lwd=0.5,col="grey20")
color.legend(0.65,0.1,0.7,0.5,legend=intervals,rect.col=colors,gradient="y",align="rb")
text(0.7,0.53,enhet,cex=1)

dev.off() 

}
