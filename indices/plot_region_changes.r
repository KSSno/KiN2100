setwd("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results")
library(ggplot2)
library("gridExtra")
 


KiNPath = "/app01-felles/iha/KiN2100"
RegionListe = read.table(paste(KiNPath,"/misc/Avrenningsregioner_liste.txt",sep=""),header=T)
RegionName <- RegionListe[5]
RegionName2 <- c("Norge","Vestlandet","Sørlandet","Østlandet","Trøndelag","Nordland",
"Troms&Finnmark")
#RegionName2 <- c("Norge","2","1","3","4","5","6")


### period
syear <- c(2041,2071)
eyear <-c(2070,2100)
plot_year <- c("2055","2085")

rcpname <- c("rcp26","rcp45")
rcpname2 <- c("RCP2.6","RCP4.5")
season_name <- c("År","Vinter","Vår","Sommer","Høst")
season_name2 <- c("Annual","Winer","Spring","Summer","Autumn")

for(iseason in 1:5) { 

png(paste(season_name2[iseason],"_change.png",sep=""), width = 940, height = 360, units = "px", pointsize = 14)

for ( j in 1: length(syear)) {

for (ii in 1:length(rcpname)) {   # 3 rcps 


for( iregion in 1:length(RegionName[,1])) {
bias_annual_1 <- read.table(paste(rcpname[ii],"_", RegionName[iregion,1],"_",syear[j],"_",eyear[j],"_",season_name[iseason],"_ensemble_means.txt",sep=""),
header= TRUE)

hist_mean <- read.table(paste(rcpname[ii],"_", RegionName[iregion,1],"_1991_2020_",season_name[iseason],"_ensemble_means.txt",sep=""),
header= TRUE)


MyData= (bias_annual_1[,6]-hist_mean[,6])/hist_mean[,6]*100

if(iregion==1&ii==1&j==1) {
out <- mean(MyData)
percentile_out <- quantile(MyData,c(0,0.25,0.5,0.75,1))
period_out <- plot_year[j]
rcp_out <- rcpname2[ii]
region_out <- RegionName2[iregion]
} else {
out <- c(out,mean(MyData))
percentile_out <- rbind(percentile_out,quantile(MyData,c(0,0.25,0.5,0.75,1)))
period_out <- c(period_out,plot_year[j])
rcp_out <- c(rcp_out,rcpname2[ii])
region_out <- c(region_out,RegionName2[iregion])
}


} # end loop iseason
} # end ii
} # end j


plot_dataframe <- data.frame(Period=period_out,RCP=rcp_out,Region=region_out,Change=out,Low=percentile_out[,2],
Up=percentile_out[,4], Min=percentile_out[,1], Median=percentile_out[,3],Max=percentile_out[,5])
#plot_dataframe$Region <- factor(plot_dataframe$Region, levels=c("1","2","3","4","5", "6","Norge")) 
plot_dataframe$Region <- factor(plot_dataframe$Region, levels=c("Sørlandet","Vestlandet","Østlandet","Trøndelag","Nordland",
"Troms&Finnmark","Norge")) 


if(iseason==1) {
p<- ggplot(plot_dataframe, aes(x=Period, fill=RCP,group = interaction(Period,RCP))) +
   geom_boxplot(
    aes(ymin = Low, lower = Low, middle = Change, upper = Up, ymax = Up),
    stat = "identity", position="dodge2",outlier.shape = NA)+
    scale_x_discrete(limits=c("2055", "2085"))+
    scale_y_continuous(limits=c(-10,10), breaks=seq(-10,10,5), expand = c(0, 0))+
    labs(title=season_name[iseason],x="", y = "%",color=NULL)+
    theme(legend.position = "bottom",axis.text=element_text(size=17),
    axis.title = element_text(size = 17),
    legend.title = element_blank(),
    legend.text = element_text(size=17),
    strip.text = element_text(size = 16),
    plot.title = element_text(size=18))+
    scale_fill_manual(values =  c("#b9dabb","#007cc1"))+
    facet_grid(~ Region) 
}

if(iseason==2) {
p<- ggplot(plot_dataframe, aes(x=Period, fill=RCP,group = interaction(Period,RCP))) +
   geom_boxplot(
    aes(ymin = Low, lower = Low, middle = Change, upper = Up, ymax = Up),
    stat = "identity", position="dodge2",outlier.shape = NA)+
    scale_x_discrete(limits=c("2055", "2085"))+
    scale_y_continuous(limits=c(-40,100), breaks=seq(-40,100,20), expand = c(0, 0))+
    labs(title=season_name[iseason],x="", y = "%",color=NULL)+
    theme(legend.position = "bottom",axis.text=element_text(size=17),
    axis.title = element_text(size = 17),
    legend.title = element_blank(),
    legend.text = element_text(size=17),
    strip.text = element_text(size = 16),
    plot.title = element_text(size=18))+
    scale_fill_manual(values =  c("#b9dabb","#007cc1"))+
    facet_grid(~ Region) 
}

if(iseason>2) {
p<- ggplot(plot_dataframe, aes(x=Period, fill=RCP,group = interaction(Period,RCP))) +
   geom_boxplot(
    aes(ymin = Low, lower = Low, middle = Change, upper = Up, ymax = Up),
    stat = "identity", position="dodge2",outlier.shape = NA)+
    scale_x_discrete(limits=c("2055", "2085"))+
    scale_y_continuous(limits=c(-40,40), breaks=seq(-40,40,20), expand = c(0, 0))+
    labs(title=season_name[iseason],x="", y = "%",color=NULL)+
     theme(legend.position = "bottom",axis.text=element_text(size=17),
    axis.title = element_text(size = 17),
    legend.title = element_blank(),
    legend.text = element_text(size=17),
    strip.text = element_text(size = 16),
    plot.title = element_text(size=18))+
    scale_fill_manual(values =  c("#b9dabb","#007cc1"))+
    facet_grid(~ Region) 
}
 print(p)
dev.off()

} # end iseason

