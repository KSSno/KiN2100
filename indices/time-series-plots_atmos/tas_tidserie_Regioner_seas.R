library(ncdf4)
source("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/smoothing.R")

#number of models
nmod <- 20

load("/lustre/storeB/project/KSS/kin2100_2024/Indices/tas_changes_regions_seasons.RData")

seas <- c("DJF","MAM","JJA","SON")

#re-read models and recalculate tables (if true)
READ=F
if(READ)
{
  Zrcp26 <- Zrcp45 <- Zssp370 <- array(NA,c(2,20,7,4)) #NF/FF, 20 runs, 7 areas, 4 seasons
  
  # Region masks
  nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/tm_region_2021d_Nr_OnSeNorgeGrid.nc")
  mask <- ncvar_get(nc,"TM-region")
  nc_close(nc)
  
  # Norway mask
  nc <- nc_open("/lustre/storeB/project/KSS/kin2100_2024/geoinfo/NorwayMaskOnSeNorgeGrid.nc")
  mask_nor <- ncvar_get(nc,"mask")
  nc_close(nc)
  
  mask <- mask*mask_nor #cut to Norway
  
  seas <- c("DJF","MAM","JJA","SON")
  for (s in 1:4)
  {
    print("#################")
    print(paste("Reading season:",seas[s]))
    ### Filelists
    # near future
    filelist_tas_rcp26_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal/",paste0("30yrmean_nf-diff.*rcp26.*",seas[s]),full.names = T)
    filelist_tas_rcp45_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal/",paste0("30yrmean_nf-diff.*rcp45.*",seas[s]),full.names = T)
    filelist_tas_ssp370_nf <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal/",paste0("30yrmean_nf-diff.*ssp370.*",seas[s]),full.names = T)
    
    # far future
    filelist_tas_rcp26_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal/",paste0("30yrmean_ff-diff.*rcp26.*",seas[s]),full.names = T)
    filelist_tas_rcp45_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal",paste0("30yrmean_ff-diff.*rcp45.*",seas[s]),full.names = T)
    filelist_tas_ssp370_ff <- list.files("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/tas/seasonal",paste0("30yrmean_ff-diff.*ssp370.*",seas[s]),full.names = T)
    
    
    #read  models
    for(i in 1:nmod)
    {
      print(paste("Reading model",i,"of",nmod))
      
      #RCP26
      nc1 <- nc_open(filelist_tas_rcp26_nf[i])
      nc2 <- nc_open(filelist_tas_rcp26_ff[i])
      #RCP45
      nc3 <- nc_open(filelist_tas_rcp45_nf[i])
      nc4 <- nc_open(filelist_tas_rcp45_ff[i])
      
      #SSP370
      nc5 <- nc_open(filelist_tas_ssp370_nf[i])
      nc6 <- nc_open(filelist_tas_ssp370_ff[i])
      
      for (j in 1:7)
      {
        regmask <- mask
        regmask[mask != j] <- NA
        regmask[mask == j] <- 1
        
        Zrcp26[1,i,j,s] <- mean(ncvar_get(nc1,"tas")*regmask,na.rm=T)
        Zrcp26[2,i,j,s] <- mean(ncvar_get(nc2,"tas")*regmask,na.rm=T)
        
        Zrcp45[1,i,j,s] <- mean(ncvar_get(nc3,"tas")*regmask,na.rm=T)
        Zrcp45[2,i,j,s] <- mean(ncvar_get(nc4,"tas")*regmask,na.rm=T)
        
        Zssp370[1,i,j,s] <- mean(ncvar_get(nc5,"tas")*regmask,na.rm=T)
        Zssp370[2,i,j,s] <- mean(ncvar_get(nc6,"tas")*regmask,na.rm=T)
      }
      
      nc_close(nc1)
      nc_close(nc2)
      nc_close(nc3)
      nc_close(nc4)
      nc_close(nc5)
      nc_close(nc6)
      
    }
  }
  
  table_nf <- array(NA,c(4,9,7))
  table_ff <- array(NA,c(4,9,7))
  
  colnames(table_nf) <- c("RCP26-snitt","lav","høy","RCP45-snitt","lav","høy","SSP370-snitt","lav","høy")
  colnames(table_ff) <- c("RCP26-snitt","lav","høy","RCP45-snitt","lav","høy","SSP370-snitt","lav","høy")
  
  rownames(table_nf) <- seas
  rownames(table_ff) <- seas
  
}

#Clear file
# write.table(NULL,"/home/andreasd/tmp/test.csv",append=F,row.names = F,col.names=F)

for (j in 1:7)
{
  print("####################")
  print(paste("REGION",j))
  # write.table(paste("REGION",j),"/home/andreasd/tmp/test.csv",append=T,row.names = F,col.names=F)
  
  for (s in 1:4)
  {
    print("#################")
    print(paste("Process season:",seas[s]))
    
    #single models plot (to check only)
    #SSP370
    plot(Zssp370[1,,j,s],xlim=c(0,45),ylim=c(-1,8),pch="+")
    points(22:41,Zssp370[2,,j,s],pch="+")
    abline(h=0)
    
    #RCP4.5
    plot(Zrcp45[1,,j,s],xlim=c(0,45),ylim=c(-1,8),pch="+")
    points(22:41,Zrcp45[2,,j,s],pch="+")
    abline(h=0)
    
    #RCP2.6
    plot(Zrcp26[1,,j,s],xlim=c(0,45),ylim=c(-1,8),pch="+")
    points(22:41,Zrcp26[2,,j,s],pch="+")
    abline(h=0)
    
    #Changes
    dmean_37 <- apply(Zssp370[,,j,s],1,mean)
    dq10_37 <- apply(Zssp370[,,j,s],1,quantile,0.1)
    dq90_37 <- apply(Zssp370[,,j,s],1,quantile,0.9)
    
    dmean_45 <- apply(Zrcp45[,,j,s],1,mean)
    dq10_45 <- apply(Zrcp45[,,j,s],1,quantile,0.1)
    dq90_45 <- apply(Zrcp45[,,j,s],1,quantile,0.9)
    
    dmean_26 <- apply(Zrcp26[,,j,s],1,mean)
    dq10_26 <- apply(Zrcp26[,,j,s],1,quantile,0.1)
    dq90_26 <- apply(Zrcp26[,,j,s],1,quantile,0.9)
    
    ###Make the timeseries plot
    k=4 #image scaling factor
    png(paste0("/home/andreasd/Documents/KiN2100_2023/Indices/plots/tas/tas_changes_",seas[s],"_TM_region_",j,".png"),width = k*1280, height = k*640,pointsize=k*28)
    
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
    yl <- c(-2.5,6.5)
    
    #Plot funnels (left part)
    plot(1901:2110,rep(0,210),xlim=c(1910,2090),ylim=yl,xaxt="n",type="l",lwd=k,lty=3,xlab="",ylab="Avvik (%)",col="grey")
    abline(h=seq(-5,10,1),col="grey",lty=3,lwd=k)
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
    
    # add obs (30-year means, black dots and 30-year GAuss filtered)
    #tas_ref <- read.table(paste0("/lustre/storeB/project/KSS/kin2100_2024/Region_series/regionserier.nye.KR/tama_1901-2021_",seas[s],".csv"),header=T,sep=";")
    ## !!!!
    ## USE abs. values and calculate deviation as the deviation files for DJF are wrong
    tas_ref <- read.table(paste0("/lustre/storeB/project/KSS/kin2100_2024/Region_series/regionserier.nye.KR/tam_1901-2021_",seas[s],".csv"),header=T,sep=";")
    tas_diff_1 <- mean(tas_ref[1:30,j+1])-mean(tas_ref[91:120,j+1])
    tas_diff_2 <- mean(tas_ref[31:60,j+1])-mean(tas_ref[91:120,j+1])
    tas_diff_3 <- mean(tas_ref[61:90,j+1])-mean(tas_ref[91:120,j+1])
    
    # print("tas. ref periods:")
    # print(round(tas_diff_1))
    # print(round(tas_diff_2))
    # print(round(tas_diff_3))
    # print(round(mean(tas_ref$GR0[71:100])))
    # print("###")
    
    points(2006,0,pch=19)
    points(1916,tas_diff_1,pch=19)
    points(1946,tas_diff_2,pch=19)
    points(1976,tas_diff_3,pch=19)
    
    # lines(tas_ref$Year,smth(tas_ref$GR0,window = 45, method = "gaussian"),lwd=2)
    lines(tas_ref$Year[10:111],smoooth_wkw(tas_ref[,j+1]-mean(tas_ref[91:120,j+1]),h=9)[10:111],lwd=2+k)
    # lines(tas_ref$Year,tas_ref[,j+1]-mean(tas_ref[91:120,j+1]),lwd=2+k,col="red")
    
    # sm2 <- ksmooth(tas_ref$Year,tas_ref$GR0,"normal",bandwidth = 24)
    # lines(sm2$x, sm2$y,col="red")
    
    #legend
    # legend("topleft",bty="n",legend=c("RCP2.6","RCP4.5","SSP3-7.0"),col=c("#0034AB","#F79420","#E71D25"),lty=1,lwd=5*k)
    legend("topleft",bty="n",legend=c("Lavt","Middels","Høyt"),col=c("#0034AB","#F79420","#E71D25"),lty=1,lwd=5*k)
    
    
    #box plots (right part)
    par(mar=c(under,0.1,over,0.1))
    
    #calculate default box-plots statistics
    bplots <- boxplot(Zrcp26[2,,j,s],Zrcp45[2,,j,s],Zssp370[2,,j,s],plot=FALSE,range=0)
    
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
    print("Near future")
    cat(paste0(round(dmean_26[1],1),"\n(",round(dq10_26[1],1),"–",round(dq90_26[1],1),")\n"))
    print("Far future")
    cat(paste0(round(dmean_26[2],1),"\n(",round(dq10_26[2],1),"–",round(dq90_26[2],1),")\n"))
    print("###")
    
    print("RCP4.5")
    print("Near future")
    cat(paste0(round(dmean_45[1],1),"\n(",round(dq10_45[1],1),"–",round(dq90_45[1],1),")\n"))
    print("Far future")
    cat(paste0(round(dmean_45[2],1),"\n(",round(dq10_45[2],1),"–",round(dq90_45[2],1),")\n"))
    
    print("###")
    print("SSP3.70")
    print("Near future")
    cat(paste0(round(dmean_37[1],1),"\n(",round(dq10_37[1],1),"–",round(dq90_37[1],1),")\n"))
    print("Far future")
    cat(paste0(round(dmean_37[2],1),"\n(",round(dq10_37[2],1),"–",round(dq90_37[2],1),")\n"))
    
    if (READ) #recalculate tables 
    {
      table_nf[s,,j] <- round(c(dmean_26[1],dq10_26[1],dq90_26[1],dmean_45[1],dq10_45[1],dq90_45[1],dmean_37[1],dq10_37[1],dq90_37[1]),1)
      table_ff[s,,j] <- round(c(dmean_26[2],dq10_26[2],dq90_26[2],dmean_45[2],dq10_45[2],dq90_45[2],dmean_37[2],dq10_37[2],dq90_37[2]),1)
    }
    
    # #Write to file
    # write.table(seas[s],"/home/andreasd/tmp/test.csv",append=T,row.names = F,col.names=F)
    # write.table(t(c(round(dmean_26,1),round(dmean_45,1),round(dmean_37,1))),"/home/andreasd/tmp/test.csv",row.names = F,col.names=F,sep=" ; ",dec=",",append=T)
    # write.table(paste0("(",round(dq10_26[1],1),"–",round(dq90_26[1],1),");(",round(dq10_45[1],1),"–",round(dq90_45[1],1),");(",round(dq10_37[1],1),"–",round(dq90_37[1],1),")"),"/home/andreasd/tmp/test.csv",row.names = F,col.names=F,sep=" ; ",dec=",",append = T,quote = F)
  }
}



# save(Zrcp26,Zrcp45,Zssp370,table_nf,table_ff,file="~/Documents/KiN2100_2023/Indices/tas_changes_regions_seasons.RData")

