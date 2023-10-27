		
##########################plotting
#library("smoother")
#senorge_pm <- read.table("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/pm/hist/results/run_yearly_region_1960-2020.txt",
#header=T)
#senorge_te <- read.table("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/tevap/hist/results/run_yearly_region_1960-2020.txt",
#header=T)

#senorge <- apply(cbind(senorge_pm[,2],senorge_te[,2]),1,mean)
#senorge <- senorge_pm[,2]
#ref <- mean(senorge[32:61])
#ys <- (smth(senorge ,window=9,method="gaussian")-ref)/ref*100

#upper boundary
#senorge_pm_upp <- read.table("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/pm/hist/results/run_yearly_percentile_norway_1960-2020.txt",
#header=T)
#senorge_te_upp <- read.table("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/sn2018v2005/raw/tevap/hist/results/run_yearly_percentile_norway_1960-2020.txt",
#header=T)

#senorge_upp <- apply(cbind(as.numeric(senorge_pm_upp[,5]),as.numeric(senorge_te_upp[,5])),1,mean)
#ys_upp <- (smth(senorge_upp,window=9,method="gaussian")-ref)/ref*100

#lower boundary

#senorge_low <- apply(cbind(senorge_pm_upp[,3],senorge_te_upp[,3]),1,mean)
#ys_low <- (smth(senorge_low,window=9,method="gaussian")-ref)/ref*100

total_run <- read.table("/data06/shh/KiN/data/total_runoff/total_runoff.txt",
header=T)

######## hist
hist <- read.table("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results/rcp45_norway_1991_2020_År_ensemble_means.txt",header=T)       
#hist_mean <- mean(hist[,6])
#hist_up <- (quantile(hist[,6],0.75)-hist_mean)/hist_mean*100
#hist_low <- (quantile(hist[,6],0.25)-hist_mean)/hist_mean*100

###### plot3 relative difference to their own model reference

sc_mean_rcp26 <- rep(NA, 2)
sc_up_rcp26 <- rep(NA, 2)
sc_low_rcp26 <- rep(NA, 2)
sc_max_rcp26 <- rep(NA, 2)
sc_min_rcp26 <- rep(NA, 2)


sc_mean_rcp45 <- rep(NA, 2)
sc_up_rcp45 <- rep(NA, 2)
sc_low_rcp45 <- rep(NA, 2)
sc_max_rcp45 <- rep(NA, 2)
sc_min_rcp45 <- rep(NA, 2)


loopid <- 1
for(i in c(2041,2071)) {
rcp26 <- read.table(paste("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results/rcp26_norway_",i,"_",i+29,"_År_ensemble_means.txt",sep=""),header=T)
rcp26_diff <- (rcp26[,6]-hist[,6])/hist[,6]*100
sc_mean_rcp26[loopid] <- mean(rcp26_diff)
sc_up_rcp26[loopid] <- quantile(rcp26_diff,0.75)
sc_low_rcp26[loopid] <- quantile(rcp26_diff,0.25)
sc_max_rcp26[loopid] <- max(rcp26_diff)
sc_min_rcp26[loopid] <- min(rcp26_diff)


rcp45 <- read.table(paste("/hdata/hmdata/KiN2100/HydMod/DistHBV/SimDistHBV/ensemble_results/rcp45_norway_",i,"_",i+29,"_År_ensemble_means.txt",sep=""),header=T)
rcp45_diff <- (rcp45[,6]-hist[,6])/hist[,6]*100
sc_mean_rcp45[loopid] <- mean(rcp45_diff)
sc_up_rcp45[loopid] <- quantile(rcp45_diff,0.75)
sc_low_rcp45[loopid] <- quantile(rcp45_diff,0.25)
sc_max_rcp45[loopid] <- max(rcp45_diff)
sc_min_rcp45[loopid] <- min(rcp45_diff)

if(i==2041) {
rcp26_diff_out <- rcp26_diff
rcp45_diff_out <- rcp45_diff
} else {
rcp26_diff_out <- cbind(rcp26_diff_out, rcp26_diff)
rcp45_diff_out <- cbind(rcp45_diff_out, rcp45_diff)
}


loopid <- loopid + 1
}


#png("/data06/shh/KiN/results/runoff_time_series.png",width = 480, height = 320)

svg("/data06/shh/KiN/results/runoff_time_series.svg",
        width = 7, height = 4.2, pointsize = 12)
par(mar=c(2.1, 4.1, 2.1, 2.1), xpd=TRUE)
plot(c(1920,2100),c(-10,10),type="n",ylab="[%]",xlab="", xaxt='n')
axis(side=1, at=seq(1920,2100,20))

#polygon(c(1964:2015,rev(1964:2015)),c(na.omit(ys_upp),rev(na.omit(ys_low))),col=adjustcolor("grey", alpha.f=0.5),border=0 )
#lines(seq(1964,2015,1),na.omit(ys),lwd=2)

polygon(c(2005, 2055, 2085,2085,2055),c(0,sc_up_rcp26,rev(sc_low_rcp26)),col=adjustcolor("#b9dabb", alpha.f=0.3),border=0 )
polygon(c(2005, 2055, 2085,2085,2055),c(0,sc_up_rcp45,rev(sc_low_rcp45)),col=adjustcolor("#007cc1", alpha.f=0.3),border=0 )

lines(c(2005, 2055, 2085),c(0,sc_mean_rcp26),col="#54ab54",lwd=3)
lines(c(2005, 2055, 2085),c(0,sc_mean_rcp45),col="#0c465f",lwd=3)

#points(total_run[,1],total_run[,3], col="grey")
lines(total_run[,1],total_run[,4], col=1,lwd=2)
lines(1931:1960, rep(-6.8, 30), lwd=2)
lines(1961:1990, rep(-5.1, 30), lwd=2)
lines(1991:2020, rep(0, 30), lwd=3)

lines(1920:2100, rep(0, length(1920:2100)), lty=2,col=1)
lines(1920:2100, rep(5, length(1920:2100)), lty=2,col=1)
lines(1920:2100, rep(-5, length(1920:2100)), lty=2,col=1)

legend("topleft",c("Observasjon","RCP2.6","RCP4.5"),text.col="white",
lty=c(1,1,1),col=c(1,"#54ab54","#0c465f"),pch=c(NA,NA,NA), lwd=c(2,2,2))

legend("topleft",c("Observasjon","RCP2.6","RCP4.5"),lty=c(1,0,0),text.col="black",
col=c("black",adjustcolor("#b9dabb", alpha.f=0.3),adjustcolor("#007cc1", alpha.f=0.3)),
pch=c(-1,15,15), pt.cex=c(1,2,2),bty = "n")



dev.off()

############## boxplot
library("ggplot2")
#png("/data06/shh/KiN/results/runoff_time_series_boxplot.png",width = 480, height = 320)
svg("/data06/shh/KiN/results/runoff_time_series_boxplot.svg",width = 7, height = 4.2)
par(mar=c(2.1, 4.1, 2.1, 2.1), xpd=TRUE)

plot_data_box <- data.frame(Year=c(rep(2050,length(rcp26_diff_out[,1])),
rep(2055,length(rcp26_diff_out[,1])),
rep(2080,length(rcp26_diff_out[,1])),
rep(2085,length(rcp26_diff_out[,1]))),
Change = c(rcp26_diff_out[,1],rcp45_diff_out[,1],rcp26_diff_out[,2],rcp45_diff_out[,2]),
RCP=c(rep("RCP26",length(rcp26_diff_out[,1])), rep("RCP45",length(rcp26_diff_out[,1])), 
rep("RCP26",length(rcp26_diff_out[,1])), rep("RCP45",length(rcp26_diff_out[,1]))))

plot_data_smooth <- data.frame(Year=1920:2100, Change=c(total_run[which(total_run[,1]>=1920),4], rep(NA,80)))
plot_data_mean1 <- data.frame(Year=1931:1960,Change=rep(-6.8, 30))
plot_data_mean2 <- data.frame(Year=1961:1990,Change=rep(-5.1, 30))
plot_data_mean3 <- data.frame(Year=1991:2020,Change=rep(-0, 30))

ggplot(plot_data_smooth) +
   geom_line(aes(x=Year,y=Change)) +
   geom_line(data= plot_data_mean1, aes(x=Year,y=Change)) +
   geom_line(data= plot_data_mean2, aes(x=Year,y=Change)) +
   geom_line(data= plot_data_mean3, aes(x=Year,y=Change)) +
#ggplot(data=plot_data_box) +
   geom_boxplot(data=plot_data_box,aes(x=Year, y=Change, group= Year, fill=RCP,col=RCP),coef=0, outlier.shape = NA) +
   coord_cartesian(ylim = c(-10, 10)) +
   scale_fill_manual(values = c(adjustcolor("#b9dabb", alpha.f=0.3),adjustcolor("#007cc1", alpha.f=0.3))) +
   scale_color_manual(values = c("#54ab54","#0c465f"))+
   labs(title="",x ="", y = "%")+
    theme_bw()

   
dev.off()


