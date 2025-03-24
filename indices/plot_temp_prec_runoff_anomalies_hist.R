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
library("crayon")

# Do you want to plot the "fancy" version of the plot? YES = TRUE, NO = FALSE
fancy <- FALSE # This option is not added for runoff

# Load smoothing function
source("/hdata/fou/personlig/ibni/kin/DP1-fortid/avrenning/smoothing.R")

# Input files (of runoff is not present, use the file plot_temp_prec_anomalies_hist.R
# https://github.com/KSSno/KiN2100/commit/6e68566a5fc0462fe000823b8f7d052b4f7a317c )
runoff_file <- "/hdata/fou/personlig/ibni/kin/DP1-fortid/avrenning/avrenningsanomali_Norge_1961-2024.txt"
temp_file   <- "/hdata/fou/personlig/ibni/kin/DP1-fortid/avrenning/Temteraturanomali_Norge_1901-2024.txt"
prec_file   <- temp_file

# temp_file <- "~/Documents/Temteraturanomali_Norge_1901-2024.txt"
# prec_file <- "~/Documents/Nedbøranomali_Norge_1991-2024.txt"

# head runoff_file
# 1960     NA 
# 1961   -3.2
# 1962   -6.6
# 1963  -16.1
# 1964    2.2

# Output directory
output_dir <- "/hdata/fou/personlig/ibni/kin/DP1-fortid/avrenning/"

# Read and preprocess anomaly data
temp_ana <- as.data.frame(read.table(temp_file,sep="\t"))
colnames(temp_ana) <- c("year","t_diff")
prec_ana <- as.data.frame(read.table(prec_file,sep="\t"))
colnames(prec_ana) <- c("year","p_diff")
runoff_ana <- as.data.frame(read.table(runoff_file,sep="\t"))
colnames(runoff_ana) <- c("year","q_diff")


# Determine the ending year (assumes that all datasets end in the same year)
end_year <- temp_ana$year[nrow(temp_ana)]

# Apply smoothing (use h=3 for 10-year smoothing; the first 3 and the last 3 years have to be removed)
smooth_end_ind   <- nrow(temp_ana) - 3
smooth_end_ind_q <- nrow(runoff_ana) - 3

temp_ana$smooth <- NA
temp_ana$smooth[4:smooth_end_ind] <- smoooth_wkw(temp_ana$t_diff,h=3)[4:smooth_end_ind]

prec_ana$smooth <- NA
prec_ana$smooth[4:smooth_end_ind] <- smoooth_wkw(prec_ana$p_diff,h=3)[4:smooth_end_ind]

runoff_ana$smooth <- NA
runoff_ana$smooth[4:smooth_end_ind_q] <- smoooth_wkw(runoff_ana$q_diff[2:65],h=3)[4:smooth_end_ind_q]
#added 2:65 in the previous line because the data file starts with 1960 NA to start plotting at 1960...
#runoff_ana$smooth[4:smooth_end_ind_q] <- smoooth_wkw(runoff_ana$q_diff,h=3)[4:smooth_end_ind_q]


# Define output file paths
png_file_temp   <- paste0(output_dir,"temperature_anomalies_1901-",end_year,".png")
png_file_prec   <- paste0(output_dir,"precipitation_anomalies_1901-",end_year,".png")
png_file_runoff <- paste0(output_dir,"runoff_anomalies_1961-",end_year,".png")

png_file_temp_fancy <- paste0(output_dir,"temperature_anomalies_1901-",end_year,"_fancy.png")
png_file_prec_fancy <- paste0(output_dir,"precipitation_anomalies_1901-",end_year,"_fancy.png")
png_file_runoff_fancy <- paste0(output_dir,"runoff_anomalies_1961-",end_year,"_fancy.png")

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
# Plot runoff Anomalies (Basic)
# -----------------------------------------------------------------------------
print(head(runoff_ana))

png(png_file_runoff, width=3000, height=2000, pointsize=15,res=300)


runoff_anom <- ggplot(runoff_ana,aes(x=year,y=q_diff)) +
  geom_col(data=filter(runoff_ana,q_diff<=0), fill = "#bf812d",width=0.8) + ##F49857"
  geom_col(data=filter(runoff_ana,q_diff>=0), fill = "#35978f",width=0.8) + ##1F7E7B #01665e
  geom_hline(yintercept=0, color = "grey30", linewidth=0.7) +
  geom_line(aes(y=smooth),linewidth=1.5) +
  scale_x_continuous(name="", limits=c(1960, end_year+1),expand=c(0,0),breaks=seq(1960,2040,20)) +
  scale_y_continuous(name="Avvik i avrenning (%)", limits=c(-30, 30),expand=c(0.05,0.05)) +
  theme_bw() + 
  theme(axis.title.y = element_text(size = rel(1.8),vjust=2),
        axis.text.y = element_text(size=rel(1.8)),
        axis.title.x=element_blank(),
        axis.text.x = element_text(size=rel(1.8)),
        axis.ticks = element_blank())

plot(runoff_anom)
dev.off()



# -----------------------------------------------------------------------------
# Plot Precipitation Anomalies (Basic)
# -----------------------------------------------------------------------------
#png(png_file_prec, width=3000, height=2000, pointsize=15,res=300)

#prec_anom <- ggplot(prec_ana,aes(x=year,y=p_diff)) +
#  geom_col(data=filter(prec_ana,p_diff<=0), fill = "#bf812d",width=0.8) + ##F49857"
#  geom_col(data=filter(prec_ana,p_diff>=0), fill = "#35978f",width=0.8) + ##1F7E7B #01665e
#  geom_hline(yintercept=0, color = "grey30", linewidth=0.7) +
#  geom_line(aes(y=smooth),linewidth=1.5) +
#  scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
#  scale_y_continuous(name="Nedbøravvik (%)", limits=c(-30, 20),expand=c(0.05,0.05)) +
#  theme_bw() + 
#  theme(axis.tile.y = element_text(size = rel(1.8),vjust=2),
#        axis.text.y = element_text(size=rel(1.8)),
#        axis.title.x=element_blank(),
#        axis.text.x = element_text(size=rel(1.8)),
#        axis.ticks = element_blank())

#plot(prec_anom)
#dev.off()


# # -----------------------------------------------------------------------------
# # Fancy Plotting (Temperature and Precipitation Anomalies)
# # -----------------------------------------------------------------------------
# if (fancy == TRUE)
# {
  # # Fancy Temperature Plot
  # png(png_file_temp_fancy, width=3000, height=2000, pointsize=15,res=300)
  
  # temp_anom_fancy <- ggplot(temp_ana,aes(x=year,y=t_diff, fill=t_diff)) +
    # geom_col(width=0.8, show.legend=FALSE) +
    # scale_fill_stepsn(colors=c("#2166ac","white","#b2182b"),
                      # values = rescale(c(min(temp_ana$t_diff),0,max(temp_ana$t_diff))),
                      # limits= c(min(temp_ana$t_diff),max(temp_ana$t_diff)), n.breaks=10) +
    # geom_hline(yintercept=0, color = "grey80", linewidth=0.7) +
    # geom_line(aes(y=smooth),linewidth=1.5,color="white") +
    # scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
    # scale_y_continuous(name="Temperaturavvik (°C)", limits=c(-3, 2),expand=c(0.05,0.05)) +
    # theme_minimal() +
    # theme(plot.background = element_rect(fill="black"),
          # panel.grid.major = element_blank(),
          # panel.grid.minor = element_blank(),
          # axis.title.y = element_text(size = rel(1.8),vjust=2,color="white"),
          # axis.text.y = element_text(size=rel(1.8),color="white"),
          # axis.title.x=element_blank(),
          # axis.text.x = element_text(size=rel(1.8),color="white"),
          # axis.ticks = element_blank())
  
  # plot(temp_anom_fancy)
  # dev.off()
  
  # # Fancy Precipitation Plot
  # png(png_file_prec_fancy, width=3000, height=2000, pointsize=15,res=300)
  
  # plot_anom_fancy <- ggplot(prec_ana,aes(x=year,y=p_diff, fill=p_diff)) +
    # geom_col(width=0.8, show.legend=FALSE) +
    # scale_fill_stepsn(colors=c("#8c510a","white","#01665e"),
                      # values = rescale(c(min(prec_ana$p_diff),0,max(prec_ana$p_diff))),
                      # limits= c(min(prec_ana$p_diff),max(prec_ana$p_diff)), n.breaks=10) +
    # geom_hline(yintercept=0, color = "grey80", linewidth=0.7) +
    # geom_line(aes(y=smooth),linewidth=1.5,color="white") +
    # scale_x_continuous(name="", limits=c(1900, end_year+1),expand=c(0,0),breaks=seq(1900,2100,20)) +
    # scale_y_continuous(name="Nedbøravvik (%)", limits=c(-30, 20),expand=c(0.05,0.05)) +
    # theme_minimal() +
    # theme(plot.background = element_rect(fill="black"),
          # panel.grid.major = element_blank(),
          # panel.grid.minor = element_blank(),
          # axis.title.y = element_text(size = rel(1.8),vjust=2,color="white"),
          # axis.text.y = element_text(size=rel(1.8),color="white"),
          # axis.title.x=element_blank(),
          # axis.text.x = element_text(size=rel(1.8),color="white"),
          # axis.ticks = element_blank())
  
  # plot(plot_anom_fancy)
  # dev.off()

#}

print(paste0("Check your recently generated files ", output_dir,"runoff_anomalies_1961-",end_year,".png"))
