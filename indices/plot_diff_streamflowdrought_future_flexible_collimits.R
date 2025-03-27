################################################################
#
# Helga Therese Tilley Tajet, Irene Brox Nilsen og Anita Verpe Dyrrdal
# Modifisert for tørkeindeks av Sigrid J. Bakke 01.10.24
#
#################################################################

rm(list=ls())
setwd("P:/klima_i_norge/analyses/streamflow_drought/")
library(ncdf4)
library(fields)
library(RColorBrewer)
library(plotrix)
library(raster)
#library(rgdal)
# hvis de ikke finnes: install.packages("rgdal", repos="http://cran.r-project.org", type="source")

#setEPS()

input <- c("P:/klima_i_norge/analyses/streamflow_drought/ifiles/")
maskpath  <- input
output  <- c("P:/klima_i_norge/analyses/streamflow_drought/ofiles/")

filename="DrgtDurationChange_dew_ssp370_2071_2100"
fil=paste0(filename,".nc4")
variabel_inn="drgt"  #variablename in file





# Choices for color legend:
collim_14_28 = F #if want limits [-14, 28] of colors to show (excluding arrows)
collim_14_14 = F #if want limits [-14, 14] of colors to show (excluding arrows)
collim_7_21  = F #if want limits [-7, 21]  of colors to show (excluding arrows)
collim_7_14  = F #if want limits [-7, 14]  of colors to show (excluding arrows)
collim_6_18  = F #if want limits [-6, 18]  of colors to show (excluding arrows)
collim_6_14  = F #if want limits [-6, 14]  of colors to show (excluding arrows)
collim_10_14 = T #if want limits [-10, 14] of colors to show (excluding arrows)


vcols <-  rev(c("#543005","#8c510a","#bf812d","#dfc27d","#f6e8c3","#f5f5f5","#c7eae5","#80cdc1","#35978f","#01665e","#003c30","#000000"))
legendunit="Dager" #https://www.utf8-chartable.de/

if(collim_14_28){
  minval_shown    = -14
  maxval_shown    =  28
  legend_interval =  3.5
  legend_tics     = c(-14,-7,-3.5,3.5,7,14,21,28)
  
  legend_labels = legend_tics
  variabel_cols = c(vcols[4],vcols[5],vcols[5],vcols[6],vcols[7],vcols[7],vcols[8],vcols[9],vcols[9],vcols[10],vcols[10],vcols[11],vcols[11],vcols[12])
  
}else if(collim_14_14){
  minval_shown    = -14
  maxval_shown    =  14
  legend_interval =  3.5
  legend_tics     = c(-14,-7,0,7,14)
  
  legend_labels = legend_tics
  #variabel_cols = c(vcols[4],vcols[5],vcols[5],vcols[6],vcols[7],vcols[7],vcols[8],vcols[9],vcols[9],vcols[10])
  #variabel_cols = c(vcols[2],vcols[3],vcols[3],vcols[5],vcols[7],vcols[7],vcols[9],vcols[11],vcols[11],vcols[12])
  variabel_cols = c(vcols[2],vcols[3],vcols[3],vcols[4],vcols[6],vcols[8],vcols[10],vcols[11],vcols[11],vcols[12])
  
}else if(collim_7_21){
  minval_shown    = -7
  maxval_shown    =  21
  legend_interval =  3.5
  legend_tics     = c(-7,0,7,14,21)
  
  legend_labels = legend_tics
  #variabel_cols = c(vcols[5],vcols[6],vcols[7],vcols[7],vcols[8],vcols[9],vcols[10],vcols[11],vcols[11],vcols[12])
  variabel_cols = c(vcols[4],vcols[5],vcols[6],vcols[8],vcols[9],vcols[10],vcols[10],vcols[11],vcols[11],vcols[12])
  
}else if(collim_7_14){
  minval_shown    = -7
  maxval_shown    =  14
  legend_interval =  3.5
  legend_tics     = c(-7,0,7,14)
  
  legend_labels = legend_tics
  #variabel_cols = c(vcols[5],vcols[6],vcols[7],vcols[7],vcols[8],vcols[9],vcols[10],vcols[11],vcols[11],vcols[12])
  #variabel_cols = c(vcols[4],vcols[5],vcols[6],vcols[8],vcols[9],vcols[10],vcols[11],vcols[12])
  variabel_cols = c(vcols[4],vcols[5],vcols[7],vcols[7],vcols[9],vcols[10],vcols[11],vcols[12])
  
}else if(collim_6_18){
  minval_shown    = -6
  maxval_shown    =  18
  legend_interval =  4
  legend_tics     = c(-6,-2,2,6,10,14,18)
  
  legend_labels = legend_tics
  variabel_cols = c(vcols[5],vcols[6],vcols[7],vcols[8],vcols[9],vcols[10],vcols[11],vcols[12])

}else if(collim_6_14){
  minval_shown    = -6
  maxval_shown    =  14
  legend_interval =  4
  legend_tics     = c(-6,-2,2,6,10,14)
  
  legend_labels = legend_tics
  variabel_cols = c(vcols[4],vcols[5],vcols[7],vcols[9],vcols[10],vcols[11],vcols[12])
  
}else if(collim_10_14){
  minval_shown    = -10
  maxval_shown    =  14
  legend_interval =  4
  legend_tics     = c(-10,-6,-2,2,6,10,14)
  
  legend_labels = legend_tics
  #variabel_cols = c(vcols[3],vcols[4],vcols[5],vcols[7],vcols[9],vcols[10],vcols[11],vcols[12])
  variabel_cols = c(vcols[3],vcols[4],vcols[5],"#ededed",vcols[9],vcols[10],vcols[11],vcols[12])
  
}
ofile = paste0(filename,"_collim_",minval_shown,"_to_",maxval_shown,".png")

#################################################################################
############################## Plotting #########################################
#################################################################################

# Norge-omriss
stiogNorgefil <- paste(maskpath, "NorwayMaskOnSeNorgeGrid.nc", sep="")
nc  <- nc_open(stiogNorgefil)
Norge_mask <- ncvar_get(nc,"mask")
nc_close(nc)
Norge_mask[is.na(Norge_mask)]=0 # setter alle NA til 0
lf <- Norge_mask
lf[is.na(lf)] <- 0


# Tørke-data
stiogfil <- paste(input,fil,sep="")
print(paste0("Input file (stiogfil) = ", input,fil))
nc <- nc_open(stiogfil)
variabel=variabel_inn	     # change the variable name into what is in the nc file, if they differ from the filename
indeks <- ncvar_get(nc, variabel)
lat <- ncvar_get(nc, "Yc") # "lat")
lon <- ncvar_get(nc, "Xc") # "lon")
nc_close(nc) # ma den lukkes hver gang? lukker fila, men har hentet ut swe, lat og lon
y = as.vector(indeks)
y = y[!is.na(y)]
print(paste0("Snow index ", variabel_inn, ": [min, max] = [",round(min(y),1),", ",round(max(y),1),"]"))

# Klargjøre tørke-data
kart_til_plot <- indeks    #Dette funker, men jeg skjonner ikke hvor verdiene ligger. # Fant bare dimensjonene: YC=nc$var$runoff$dim[[1]]$vals Xc=nc$var$runoff$dim[[2]]$vals
kart_til_plot <- kart_til_plot/Norge_mask  # hva gjor denne? Fjerner hav og Sverige?
kart_til_plot <- kart_til_plot[,1550:1]
kart_til_plot[kart_til_plot>maxval_shown+0.1] <- maxval_shown+0.9

print(paste("Number of gridcells with value<",minval_shown,": ",sum(kart_til_plot[kart_til_plot<minval_shown]*0+1,na.rm=TRUE)))# only 9 values below -14
#"Number of gridcells with value< -6 :  2849"
#"Number of gridcells with value< -10 :  145"

kart_til_plot[kart_til_plot<minval_shown-0.1] <- minval_shown-0.9


#################################


zlimval <- c(minval_shown-legend_interval/2,maxval_shown+legend_interval/2)
rand <- c(minval_shown-legend_interval,maxval_shown+legend_interval)
zlim=rand


png(paste0(output,ofile), width=2000, height=2500, pointsize=20,res=300)
par(mar=c(0.5,0.2,0,0.3))

image(kart_til_plot, xlab="",ylab="",xaxt="n",yaxt="n",zlim=rand,col=variabel_cols,bty="n", main="")
contour(lf[,1550:1],add=T,levels = 0.5,drawlabels = FALSE,lwd=1,col="grey20")
imagePlot(kart_til_plot, legend.lab="",legend.line=2.7 ,axis.args=list(tick=FALSE,at=legend_tics,labels=legend_labels),
          legend.shrink=0.6,legend.only=TRUE, zlim=zlimval, col=variabel_cols, smallplot=c(0.7,0.75,0.1,0.6), upperTriangle=T, lowerTriangle=T)
text(0.77,0.68, legendunit, font=1)


dev.off()

print(paste0("Ofile: ", output,ofile))

print(paste0(variabel_inn, ": [min, max] = [",round(min(y),1),", ",round(max(y),1),"]"))