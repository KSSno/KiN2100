# -----------------------------------------------------------------------------
# Script Name: Climate Anomaly Plotter
# Description: This script reads temperature and precipitation anomaly data 
#              for Norway, applies smoothing, and generates plots of the 
#              anomalies with a basic and a fancy (can be used in presentations, posters media etc.) style.
# 
# Input Files: 
#   - Temperature anomaly: Temteraturanomali_Norge_1901-2022.txt (or something like that)
#   - Precipitation anomaly: Nedbøranomali_Norge_1991-2022.txt (or something like that)
# Output Files:
#   - PNG plots of temperature and precipitation anomalies
#
# Required Libraries: ggplot2, scales, dplyr
# Author: Julia Lutz, Meteorologisk institutt
# Date: 28.11.2024
# -----------------------------------------------------------------------------

# Load required libraries
library("ggplot2")
library("scales")
library("dplyr")

# Do you want to plot the "fancy" version of the plot? YES = TRUE, NO = FALSE
fancy <- TRUE

# Load smoothing function
source("/lustre/storeB/project/KSS/kin2100_2024/Indices/30yr-diff-files_for_plotting/smoothing.R")

# Input file paths
temp_file <- "~/Documents/Temteraturanomali_Norge_1901-2024.txt"
prec_file <- "~/Documents/Nedbøranomali_Norge_1991-2024.txt"

# Output directory
output_dir <- "~/Documents/results/KiN_misc/"

# Read and preprocess anomaly data
temp_ana <- as.data.frame(read.table(temp_file,sep="\t"))
colnames(temp_ana) <- c("year","t_diff")
prec_ana <- as.data.frame(read.table(prec_file,sep="\t"))
colnames(prec_ana) <- c("year","p_diff")

# Determine the ending year (assumes both datasets end in the same year)
end_year <- temp_ana$year[nrow(temp_ana)]

# Apply smoothing (use h=3 for 10-year smoothing; the first 3 and the last 3 years have to be removed)
smooth_end_ind <- nrow(temp_ana) - 3

temp_ana$smooth <- NA
temp_ana$smooth[4:smooth_end_ind] <- smoooth_wkw(temp_ana$t_diff,h=3)[4:smooth_end_ind]

prec_ana$smooth <- NA
prec_ana$smooth[4:smooth_end_ind] <- smoooth_wkw(prec_ana$p_diff,h=3)[4:smooth_end_ind]

# Define output file paths
png_file_temp <- paste0(output_dir,"temperature_anomalies_1901-",end_year,".png")
png_file_prec <- paste0(output_dir,"precipitation_anomalies_1901-",end_year,".png")
png_file_temp_fancy <- paste0(output_dir,"temperature_anomalies_1901-",end_year,"_fancy.png")
png_file_prec_fancy <- paste0(output_dir,"precipitation_anomalies_1901-",end_year,"_fancy.png")

# -----------------------------------------------------------------------------
# Plot Temperature Anomalies (Basic)
# -----------------------------------------------------------------------------
png(png_file_temp, width=3000, height=2000, pointsize=15,res=300)

temp_anom <- ggplot(temp_ana,aes(x=year,y=t_diff)) +
  geom_col(data=filter(temp_ana,t_diff<=0), fill = "#4F81BD",width=0.8) +
  geom_col(data=filter(temp_ana,t_diff>=0), fill = "#C00000",width=0.8) +
  geom_hline(yintercept=0, color = "grey30", linewidth=0.7) +
  geom_line(aes(y=smooth),linewidth=1.5) +
  scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2040,20)) +
  scale_y_continuous(name="Temperaturavvik (°C)", limits=c(-3, 2),expand=c(0.05,0.05)) +
  theme_bw() + 
  theme(axis.title.y = element_text(size = rel(1.8),vjust=2),
        axis.text.y = element_text(size=rel(1.8)),
        axis.title.x=element_blank(),
        axis.text.x = element_text(size=rel(1.8)),
        axis.ticks = element_blank())

plot(temp_anom)
dev.off()

# -----------------------------------------------------------------------------
# Plot Precipitation Anomalies (Basic)
# -----------------------------------------------------------------------------
png(png_file_prec, width=3000, height=2000, pointsize=15,res=300)

prec_anom <- ggplot(prec_ana,aes(x=year,y=p_diff)) +
  geom_col(data=filter(prec_ana,p_diff<=0), fill = "#bf812d",width=0.8) + ##F49857"
  geom_col(data=filter(prec_ana,p_diff>=0), fill = "#35978f",width=0.8) + ##1F7E7B #01665e
  geom_hline(yintercept=0, color = "grey30", linewidth=0.7) +
  geom_line(aes(y=smooth),linewidth=1.5) +
  scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
  scale_y_continuous(name="Nedbøravvik (%)", limits=c(-30, 20),expand=c(0.05,0.05)) +
  theme_bw() + 
  theme(axis.title.y = element_text(size = rel(1.8),vjust=2),
        axis.text.y = element_text(size=rel(1.8)),
        axis.title.x=element_blank(),
        axis.text.x = element_text(size=rel(1.8)),
        axis.ticks = element_blank())

plot(prec_anom)
dev.off()


# -----------------------------------------------------------------------------
# Fancy Plotting (Temperature and Precipitation Anomalies)
# -----------------------------------------------------------------------------
if (fancy == TRUE)
{
  # Fancy Temperature Plot
  png(png_file_temp_fancy, width=3000, height=2000, pointsize=15,res=300)
  
  temp_anom_fancy <- ggplot(temp_ana,aes(x=year,y=t_diff, fill=t_diff)) +
    geom_col(width=0.8, show.legend=FALSE) +
    scale_fill_stepsn(colors=c("#2166ac","white","#b2182b"),
                      values = rescale(c(min(temp_ana$t_diff),0,max(temp_ana$t_diff))),
                      limits= c(min(temp_ana$t_diff),max(temp_ana$t_diff)), n.breaks=10) +
    geom_hline(yintercept=0, color = "grey80", linewidth=0.7) +
    geom_line(aes(y=smooth),linewidth=1.5,color="white") +
    scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
    scale_y_continuous(name="Temperaturavvik (°C)", limits=c(-3, 2),expand=c(0.05,0.05)) +
    theme_minimal() +
    theme(plot.background = element_rect(fill="black"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title.y = element_text(size = rel(1.8),vjust=2,color="white"),
          axis.text.y = element_text(size=rel(1.8),color="white"),
          axis.title.x=element_blank(),
          axis.text.x = element_text(size=rel(1.8),color="white"),
          axis.ticks = element_blank())
  
  plot(temp_anom_fancy)
  dev.off()
  
  # Fancy Precipitation Plot
  png(png_file_prec_fancy, width=3000, height=2000, pointsize=15,res=300)
  
  plot_anom_fancy <- ggplot(prec_ana,aes(x=year,y=p_diff, fill=p_diff)) +
    geom_col(width=0.8, show.legend=FALSE) +
    scale_fill_stepsn(colors=c("#8c510a","white","#01665e"),
                      values = rescale(c(min(prec_ana$p_diff),0,max(prec_ana$p_diff))),
                      limits= c(min(prec_ana$p_diff),max(prec_ana$p_diff)), n.breaks=10) +
    geom_hline(yintercept=0, color = "grey80", linewidth=0.7) +
    geom_line(aes(y=smooth),linewidth=1.5,color="white") +
    scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
    scale_y_continuous(name="Nedbøravvik (%)", limits=c(-30, 20),expand=c(0.05,0.05)) +
    theme_minimal() +
    theme(plot.background = element_rect(fill="black"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title.y = element_text(size = rel(1.8),vjust=2,color="white"),
          axis.text.y = element_text(size=rel(1.8),color="white"),
          axis.title.x=element_blank(),
          axis.text.x = element_text(size=rel(1.8),color="white"),
          axis.ticks = element_blank())
  
  plot(plot_anom_fancy)
  dev.off()
}
