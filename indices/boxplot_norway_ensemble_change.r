setwd("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results")
library(ggplot2)
library("gridExtra")
 


KiNPath = "/app01-felles/iha/KiN2100"
RegionListe = read.table(paste(KiNPath,"/misc/Avrenningsregioner_liste.txt",sep=""),header=T)
RegionName <- RegionListe[5]

### period
syear <- c(2041,2071)
eyear <-c(2070,2100)

rcpname <- c("rcp26","rcp45")
rcpname2 <- c("RCP2.6","RCP4.5")
season_name <- c("År","Vinter","Vår","Sommer","Høst")
season_name2 <- c("Annual","Winer","Spring","Summer","Autumn")

uncertainty_annual <- read.table("uncertainty_annual.dat",header=T)
uncertainty_season <- read.table("uncertainty_season.dat",header=T)

#for( iregion in 1:length(RegionName[,1])) {
iregion <-1
png(paste(RegionName[iregion,1],"_change_boxplot.png",sep=""), width = 800, height = 360, units = "px", pointsize = 14)

for ( j in 1: length(syear)) {

for (ii in 1:length(rcpname)) {   # 3 rcps 

for(iseason in 1:5) { 

bias_annual_1 <- read.table(paste(rcpname[ii],"_", RegionName[iregion,1],"_",syear[j],"_",eyear[j],"_",season_name[iseason],"_ensemble_means.txt",sep=""),
header= TRUE)

hist_mean <- read.table(paste(rcpname[ii],"_", RegionName[iregion,1],"_1991_2020_",season_name[iseason],"_ensemble_means.txt",sep=""),
header= TRUE)


MyData= (bias_annual_1[,6]-hist_mean[,6])/hist_mean[,6]*100

if(iseason==1&ii==1) {
out <- mean(MyData)
percentile_out <- quantile(MyData,c(0,0.25,0.5,0.75,1))
period_out <- paste(syear[j],"_",eyear[j],sep="")
rcp_out <- rcpname2[ii]
region_out <- RegionName[iregion,1]
season_out <- season_name[iseason]
} else {
out <- c(out,mean(MyData))
percentile_out <- rbind(percentile_out,quantile(MyData,c(0,0.25,0.5,0.75,1)))
period_out <- c(period_out,paste(syear[j],"_",eyear[j],sep=""))
rcp_out <- c(rcp_out,rcpname2[ii])
region_out <- c(region_out,RegionName[iregion,1])
season_out <- c(season_out,season_name[iseason])
}


} # end loop iseason
} # end ii
plot_dataframe <- data.frame(Period=period_out,RCP=rcp_out,Region=region_out,Season= season_out,Change=out,Low=percentile_out[,2],
Up=percentile_out[,4], Min=percentile_out[,1], Median=percentile_out[,3],Max=percentile_out[,5])

if(j==1) {
p1 <- ggplot(plot_dataframe, aes(x=Season, fill=RCP)) +
   geom_boxplot(
    aes(ymin = Low, lower = Low, middle = Change, upper = Up, ymax = Up),
    stat = "identity", position=position_dodge(1),outlier.shape = NA)+     #, width=0.5
    scale_x_discrete(limits=c("Vinter", "Vår", "Sommer","Høst","År"))+
    scale_y_continuous(limits=c(-40,60), breaks=seq(-40,60,20), expand = c(0, 0))+
    labs(title=paste(syear[j],"-",eyear[j],sep=""),x="", y = "%",color=NULL)+
    theme(legend.position = c(0.85, 0.9),axis.text=element_text(size=15),
    axis.title = element_text(size = 15),
    legend.title = element_blank(),
    legend.text = element_text(size=15),
    plot.title = element_text(size=16))+
    scale_fill_manual(values =  c("#b9dabb","#007cc1"))
    } else {
p2 <- ggplot(plot_dataframe, aes(x=Season, fill=RCP)) +
   geom_boxplot(
    aes(ymin = Low, lower = Low, middle = Change, upper = Up, ymax = Up),
    stat = "identity", position=position_dodge(1),outlier.shape = NA)+
    scale_x_discrete(limits=c("Vinter", "Vår", "Sommer","Høst","År"))+
    scale_y_continuous(limits=c(-40,60), breaks=seq(-40,60,20), expand = c(0, 0))+
    labs(title=paste(syear[j],"-",eyear[j],sep=""),x="", y = "%",color=NULL)+
    theme(legend.position = c(0.85, 0.9),axis.text=element_text(size=15),
    axis.title = element_text(size = 15),
    legend.title = element_blank(),
    legend.text = element_text(size=15),
    plot.title = element_text(size=16))+
    scale_fill_manual(values =  c("#b9dabb","#007cc1"))

}

} # end j



grid.arrange(p1, p2, nrow = 1)    
dev.off()

#} # end region

