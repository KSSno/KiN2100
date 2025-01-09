library(ncdf4)
source("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/smoothing.R")

#number of models
nmod <- 20

#re-read models (if true)
READ=T
if(READ)
{
  Zrcp26 <- Zrcp45 <- Zssp370 <- array(NA,c(2,20,4))
  
  # Norway mask
  nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/NorwayMaskOnSeNorgeGrid.nc")
  mask <- ncvar_get(nc,"mask")
  nc_close(nc)
  
  seas <- c("DJF","MAM","JJA","SON")
  for (s in 1:4)
  {
    print("#################")
    print(paste("Reading season:",seas[s]))
    ### Filelists
    # near future
    filelist_wind_rcp26_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal/",paste0("30yrmean_nf-change.*rcp26.*",seas[s]),full.names = T)
    filelist_wind_rcp45_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal/",paste0("30yrmean_nf-change.*rcp45.*",seas[s]),full.names = T)
    filelist_wind_ssp370_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal/",paste0("30yrmean_nf-change.*ssp370.*",seas[s]),full.names = T)
    
    # far future
    filelist_wind_rcp26_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal/",paste0("30yrmean_ff-change.*rcp26.*",seas[s]),full.names = T)
    filelist_wind_rcp45_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal",paste0("30yrmean_ff-change.*rcp45.*",seas[s]),full.names = T)
    filelist_wind_ssp370_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/sfcWind/seasonal",paste0("30yrmean_ff-change.*ssp370.*",seas[s]),full.names = T)
    
    
    #read  models
    for(i in 1:nmod)
    {
      print(paste("Reading model",i,"of",nmod))
      
      #RCP26
      nc <- nc_open(filelist_wind_rcp26_nf[i])
      Zrcp26[1,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
      nc <- nc_open(filelist_wind_rcp26_ff[i])
      Zrcp26[2,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
      
      #RCP45
      nc <- nc_open(filelist_wind_rcp45_nf[i])
      Zrcp45[1,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
      nc <- nc_open(filelist_wind_rcp45_ff[i])
      Zrcp45[2,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
      
      #SSP370
      nc <- nc_open(filelist_wind_ssp370_nf[i])
      Zssp370[1,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
      nc <- nc_open(filelist_wind_ssp370_ff[i])
      Zssp370[2,i,s] <- mean(ncvar_get(nc,"sfcWind")*mask,na.rm=T)
      nc_close(nc)
    }
  }
}

for (s in 1:4)
{
  print("#################")
  print(paste("Process season:",seas[s]))
  
  #single models plot (to check only)
  #SSP370
  plot(Zssp370[1,,s],xlim=c(0,45),ylim=c(-50,50),pch="+")
  points(22:41,Zssp370[2,,s],pch="+")
  abline(h=0)
  
  #RCP4.5
  plot(Zrcp45[1,,s],xlim=c(0,45),ylim=c(-50,50),pch="+")
  points(22:41,Zrcp45[2,,s],pch="+")
  abline(h=0)
  
  #RCP2.6
  plot(Zrcp26[1,,s],xlim=c(0,45),ylim=c(-50,50),pch="+")
  points(22:41,Zrcp26[2,,s],pch="+")
  abline(h=0)
  
  #Changes
  dmean_37 <- apply(Zssp370[,,s],1,mean)
  dq10_37 <- apply(Zssp370[,,s],1,quantile,0.1)
  dq90_37 <- apply(Zssp370[,,s],1,quantile,0.9)
  
  dmean_45 <- apply(Zrcp45[,,s],1,mean)
  dq10_45 <- apply(Zrcp45[,,s],1,quantile,0.1)
  dq90_45 <- apply(Zrcp45[,,s],1,quantile,0.9)
  
  dmean_26 <- apply(Zrcp26[,,s],1,mean)
  dq10_26 <- apply(Zrcp26[,,s],1,quantile,0.1)
  dq90_26 <- apply(Zrcp26[,,s],1,quantile,0.9)
  
  ###Make the timeseries plot
  k=4 #image scaling factor
  png(paste0("/home/andreasd/Documents/KiN2100_2023/Indices/plots/sfcWind/sfcWind_changes_",seas[s],".png"),width = k*1280, height = k*640,pointsize=k*28)
  
  #x-coordinates of polygon
  xpoly <- c(2011,2056,2086,2086,2056,2011)
  ymid26 <- c(dq10_26[1],dq90_26[1])
  yend26 <- c(dq10_26[2],dq90_26[2])
  ymid45 <- c(dq10_45[1],dq90_45[1])
  yend45 <- c(dq10_45[2],dq90_45[2])
  ymid37 <- c(dq10_37[1],dq90_37[1])
  yend37 <- c(dq10_37[2],dq90_37[2])
  ystart26 <- ymid26/50*5 # Change from 2006 to 2056 scaled to 2011
  ystart45 <- ymid45/50*5
  ystart37 <- ymid37/50*5
  
  # plot layout 
  layout(t(1:2),widths=8,1)
  
  # margins and y-limits
  # some MUST be identical for both sub-plots
  under <- 3.2
  over <- 0.1
  par(mar=c(under,4,over,0.5))
  yl <- c(-6,6)
  
  #Plot funnels (left part)
  plot(1901:2110,rep(0,210),xlim=c(1990,2090),ylim=yl,xaxt="n",type="l",lwd=k,lty=3,xlab="",ylab="Avvik (%)",col="grey")
  abline(h=seq(-6,6,1),col="grey",lty=3,lwd=k)
  abline(v=seq(1900,2020,10),col="grey",lty=3,lwd=k)
  abline(v=c(2038,2056,2071,2086),col="grey",lty=3,lwd=k)
  box(lwd=k)
  
  axis(1,at=seq(1900,2020,20))
  axis(1,at=c(2056,2086),labels = c("2041-\n2070","2071-\n2100"),padj=0.57)
  
  polygon(xpoly,c(ystart26[1],ymid26[1],yend26,ymid26[2],ystart26[2]),col = "#0034AB4D", border = "#0034AB4D")
  polygon(xpoly,c(ystart45[1],ymid45[1],yend45,ymid45[2],ystart45[2]),col = "#F794204D", border = "#F794204D")
  polygon(xpoly,c(ystart37[1],ymid37[1],yend37,ymid37[2],ystart37[2]),col = "#E71D254D", border = "#E71D254D")
  
  lines(xpoly[1:3],c(dmean_26[1]/50*5,dmean_26),col="#0034AB",lwd=2+k)
  points(xpoly[2:3],dmean_26,col="#0034AB",pch=19)
  lines(xpoly[1:3],c(dmean_45[1]/50*5,dmean_45),col="#F79420",lwd=2+k)
  points(xpoly[2:3],dmean_45,col="#F79420",pch=19)
  lines(xpoly[1:3],c(dmean_37[1]/50*5,dmean_37),col="#E71D25",lwd=2+k)
  points(xpoly[2:3],dmean_37,col="#E71D25",pch=19)
  
  #no obs (so far)
  
  #legend
  # legend("topleft",bty="n",legend=c("RCP2.6","RCP4.5","SSP3-7.0"),col=c("#0034AB","#F79420","#E71D25"),lty=1,lwd=5*k)
  legend("topleft",bty="n",legend=c("Lavt","Middels","Høyt"),col=c("#0034AB","#F79420","#E71D25"),lty=1,lwd=5*k)
  
  
  #box plots (right part)
  par(mar=c(under,0.1,over,0.1))
  
  #calculate default box-plots statistics
  bplots <- boxplot(Zrcp26[2,,s],Zrcp45[2,,s],Zssp370[2,,s],plot=FALSE,range=0)
  
  # Adjust box-plots:
  # IQR --> Q10 to Q90
  # Median  --> mean
  bplots$stats[2,] <- c(dq10_26[2],dq10_45[2],dq10_37[2])
  bplots$stats[3,] <- c(dmean_26[2],dmean_45[2],dmean_37[2])
  bplots$stats[4,] <- c(dq90_26[2],dq90_45[2],dq90_37[2])
  
  #plot
  bxp(bplots,boxfill=c("#0034AB4D","#F794204D","#E71D254D"),whisklty=1,staplewex=0,border=c("#0034AB","#F79420","#E71D25"),lwd=2+k,yaxt="n",ylim=yl,axes=F)
  
  #reset layout
  layout(1)
  
  #close png
  dev.off()
  
  options(OutDec=",")
  
  print("RCP2.6")
  # print("Near future")
  cat(paste0(round(dmean_26[1],1),"\n(",round(dq10_26[1],1),"–",round(dq90_26[1],1),")\n"))
  # print("Far future")
  cat(paste0(round(dmean_26[2],1),"\n(",round(dq10_26[2],1),"–",round(dq90_26[2],1),")\n"))
  # print("###")
  
  print("RCP4.5")
  # print("Near future")
  cat(paste0(round(dmean_45[1],1),"\n(",round(dq10_45[1],1),"–",round(dq90_45[1],1),")\n"))
  # print("Far future")
  cat(paste0(round(dmean_45[2],1),"\n(",round(dq10_45[2],1),"–",round(dq90_45[2],1),")\n"))
  
  # print("###")
  print("SSP3.70")
  # print("Near future")
  cat(paste0(round(dmean_37[1],1),"\n(",round(dq10_37[1],1),"–",round(dq90_37[1],1),")\n"))
  # print("Far future")
  cat(paste0(round(dmean_37[2],1),"\n(",round(dq10_37[2],1),"–",round(dq90_37[2],1),")\n"))
  
}
