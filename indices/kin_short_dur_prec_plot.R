#library(readxl)

options(OutDec=",")

#sm <- as.data.frame(read_excel("/lustre/storeB/project/fou/mk/klima/anitavd/KSS/nyKiN2100/Korttidsnedbør/Data/geonor/SM.geonor.xlsx",sheet = 1))
sm <- as.data.frame(read.table("~/Documents/SM.geonor.update2025.csv",header=TRUE,sep=";"))

st <- c(12680,18700,38140,40880,44300,56420,58900,68860,71000,76530,90400,93301)
names <- c("Lillehammer","Oslo","Landvik","Hovden","Særheim","Furuneset","Stryn","Trondheim","Steinkjer","Tjøtta",
           "Tromsø","Suolovuopmi-Lulit")
fylke <- c("Innlandet","Oslo","Agder","Agder","Rogaland","Vestland","Vestland","Trøndelag","Trøndelag","Nordland","Troms",
           "Finnmark")

col.summer <- "#6a3d9a" #"#cab2d6" # #rgb(185/255,218/255,187/255)
col.spring <- "#33a02c" #"#b2df8a" # #rgb(244/255,152/255,87/255)
col.fall <- "#ff7f00" #"#fdbf6f" # #rgb(228/255,202/255,84/255)
col.winter <- "#1f78b4" #"#a6cee3" # #rgb(141/255,183/255,203/255)
perc <- array(NA,dim=c(length(st),5))
ylim <- c(0,28)

png(file=("~/Documents/results/KiN_misc/boxplot.all.geonor_1t_test_2025.png"),width=2000, height=2000, pointsize=10,res=300)
par(mfrow=c(4,1))

for (t in 1:4) # Loop over boxplot rows
{
  data_row <- array(NA, c(20,12)) # Dummy matrix with c(number of years,number of stations * number of seasons)
  for (s in 1:3) # Loop over stations in a row
  {
    stnr <- st[(t-1)*3+s]
    
    data_row[,(s-1)*4+1] <- as.numeric(sm$Spring[which(sm$Stnr==stnr)])
    data_row[,(s-1)*4+2] <- as.numeric(sm$Summer[which(sm$Stnr==stnr)])
    data_row[,(s-1)*4+3] <- as.numeric(sm$Fall[which(sm$Stnr==stnr)])
    data_row[,(s-1)*4+4] <- as.numeric(sm$Winter[which(sm$Stnr==stnr)])
    
    data_row[data_row>100] <- NA
  }
  
  idx <- (t-1)*3+1
  stname <- names[idx:(idx+2)]
  num <- st[idx:(idx+2)]
  fylke_idx <- fylke[idx:(idx+2)]
  
  par(mar = c(2,5,0,0))

  boxplot(data_row, boxfill = NA, border = NA,axes=FALSE,ylim=ylim,outline=FALSE,whisklty=0,staplelty=0,boxwex=0.5,xlim=c(0.5,11.25))
  boxplot(data_row[,seq(1,12,4)], xaxt = "n", add = TRUE, col=col.spring,boxwex=0.4,
          at = seq(1,12,4) - 0.25,outline=FALSE,whisklty=0,staplelty=0,axes=FALSE)
  boxplot(data_row[,seq(2,12,4)], xaxt = "n", add = TRUE, col=col.summer,boxwex=0.4,
          at = seq(1,12,4) + 0.5,outline=FALSE,whisklty=0,staplelty=0,axes=FALSE)
  boxplot(data_row[,seq(3,12,4)], xaxt = "n", add = TRUE, col=col.fall,boxwex=0.4,
          at = seq(1,12,4) + 1.25,outline=FALSE,whisklty=0,staplelty=0,axes=FALSE)
  boxplot(data_row[,seq(4,12,4)], xaxt = "n", add = TRUE, col=col.winter,boxwex=0.4,
          at = seq(1,12,4) + 2,outline=FALSE,whisklty=0,staplelty=0,axes=FALSE)
  
  axis(1,at =seq(1,12,4)+0.75,labels=paste0(stname," (",num,") \n",fylke_idx),tick=FALSE,line=-0.4,cex.axis=1.5)
  
  text(seq(1,12,4)-0.25,apply(data_row[,seq(1,12,4)],2,quantile,0.75,na.rm=T)+2,
       round(apply(data_row[,seq(1,12,4)],2,max,na.rm=T),1),col="black",cex=1,font=2)
  text(seq(1,12,4)+0.5,apply(data_row[,seq(2,12,4)],2,quantile,0.75,na.rm=T)+2,
       round(apply(data_row[,seq(2,12,4)],2,max,na.rm=T),1),col="black",cex=1,font=2)
  text(seq(1,12,4)+1.25,apply(data_row[,seq(3,12,4)],2,quantile,0.75,na.rm=T)+2,
       round(apply(data_row[,seq(3,12,4)],2,max,na.rm=T),1),col="black",cex=1,font=2)
  text(seq(1,12,4)+2,apply(data_row[,seq(4,12,4)],2,quantile,0.75,na.rm=T)+2,
       round(apply(data_row[,seq(4,12,4)],2,max,na.rm=T),1),col="black",cex=1,font=2)
  
  axis(2,cex.axis=1.3)
}
mtext("Nedbør (mm)", side=2,outer=TRUE,line=-2,cex=1.3)

dev.off()
