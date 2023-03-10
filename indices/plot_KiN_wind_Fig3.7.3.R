###################################################################################################
#
# Plot interpolated nora3 windspeed index 1991-2020 for Norway in KiN2100 style
#
# Used as Fig 3.7.3 in KiN2100 historical wind chapter
#
# Jan Erik Haugen (based on example from Anita Verpe Dyrrdal)
#
###################################################################################################

# libraries
library(stars)
library(ncdf4)
library(rnaturalearth)
library(plotrix)
library(fields)
library(rgdal)

# input and output directories
input <- "/lustre/storeB/users/janeh/KiN2100_ny/"
inputb <- "/lustre/storeB/project/metkl/klinogrid/geoinfo/TM_WORLD_BORDERS_LATLON/"
output <- "/lustre/storeB/users/janeh/KiN2100_ny/"

# loop over indices
 for (param in c("frge25","frlt4")) {
#param <- "frge25"
#param <- "frlt4"

# read data (hours per year or fraction in %)
if (param == "frge25") {nc <- nc_open(paste0(input,"ws100",param,"_yr-lcc_1991-2020_hours_per_year.nc")) }
if (param == "frlt4" ) {nc <- nc_open(paste0(input,"ws100",param,"_yr-lcc_1991-2020.nc")) }
x <- ncvar_get(nc,"x")
y <- ncvar_get(nc,"y")
index <- ncvar_get(nc,"wind_speed_freq")
# proj4 is present as attribute in the netcdf file
#proj4 <- "+proj=lcc +lat_0=63 +lon_0=15 +lat_1=63 +lat_2=63 +no_defs +R=6.371e+06"
proj4 <- ncatt_get(nc,"projection_lambert")$proj4
nc_close(nc)
# landcontours
bord <- readOGR(paste0(inputb,"TM_WORLD_BORDERS-0.2.shp"),"TM_WORLD_BORDERS-0.2")

# map is upside down
y <- y[length(y):1]
index <- index[,length(y):1]

# convert from lcc to lat/lon
x_2d <- rep(x,length(y))
y_2d <- rep(y,each=length(x))
res <- project(cbind(x_2d,y_2d), proj4, inv=TRUE)

# transform to 2d matrix as for index
lon <- matrix(res[,1],nrow=length(x),ncol=length(y))
lat <- matrix(res[,2],nrow=length(x),ncol=length(y))

# star object in longitude and latitude grid
s <- st_as_stars(index)
s1 <- st_as_stars(s, curvilinear=list(X1=lon,X2=lat))

# min and max used to define break limits
minv <- min(index,na.rm=T)
maxv <- max(index,na.rm=T)
cat("param,min,max=",param,minv,maxv,"\n")

# plot in predefined intervals for palette from yr.no
if (param == "frge25") {
ncol <- 12
coltab <- rep(NA,ncol)
breaks <- rep(NA,ncol+1)
coltab <- c('#b4dbad','#8cd2ae','#62c7b7','#3cb9c5','#30a5d3','#458ed6','#5576cb','#5d5dbc','#5f43a8','#5b278d','#4d0a6c','#310046')
# TEST
# approx. breaks from Cristians plot
#breaks <- c(0.0,1.0,6.0,12.0,18.0,28.0,34.0,42.0,51.0,60.0,68.0,180.0,430.0)
# END TEST
# breaks with multiple of hours per day
breaks <- c(0.0,1.0,6.0,12.0,18.0,24.0,36.0,48.0,72.0,108.0,192.0,360.0,720.0)
}
if (param == "frlt4") {
# 9 colours (10 breaks)
ncol <- 9
coltab <- rep(NA,ncol)
breaks <- rep(NA,ncol+1)
#coltab <- c('#b4dbad','#62c7b7','#3cb9c5','#30a5d3','#5576cb','#5d5dbc','#5f43a8','#4d0a6c','#310046')
 coltab <- c('#b4dbad','#8cd2ae','#62c7b7','#3cb9c5','#30a5d3','#5576cb','#5d5dbc','#5f43a8','#4d0a6c')
# reversed palette
coltab <- coltab[ncol:1]
# TEST
# full palette: approx. breaks from Cristians plot (tested with full palett)
#breaks <- c(728,825,876,915,950,990,1015,1037,1068,1127,1237,4425,7836)
# convert to fraction in %
#breaks <- breaks/(24*365.25)*100.
# END TEST
# 9 colours (10 breaks)
breaks <- c(7.5,10.0,11.0,12.0,13.0,14.0,15.0,25.0,50.0,90.0)
}
cat("breaks=",breaks,"\n")

# labels for legend
lab <- rep(NA,2*ncol-1)
j <- 1; lab[j] <- ""; for (i in 2:ncol) { lab[j+1] <- paste0("  ",breaks[i]); lab[j+2] <- "     "; j <- j+2; }

# assign output file and format
if (param == "frge25") { plotname <- paste0("ws100",param,"_yr-lcc_1991-2020_hours_per_year") }
if (param == "frlt4" ) { plotname <- paste0("ws100",param,"_yr-lcc_1991-2020_fraction_in_pc") }

############################# OUTPUT IN PNG OR PDF ############################################
# adjust width and height as needed
#png(paste0(output,plotname,".png"), width=1905, height=2500, pointsize=14,res=300)
# the output was written in pdf, followed by shell command $ pdftoppm -png <file>.pdf > <file>.png
 pdf(paste0(output,plotname,".pdf"), width=8, height=10.5) #  res=300
###############################################################################################

# plot map and borders
# par-statement without borders and axes labels used in final version
 par(mar=c(0,0,0,0))
plot(bord[c(45,60,155,191),],xlim=c(1.0,31.0),ylim=c(55.5,72.0),axes=T)
plot(s1,as_points=FALSE,breaks=breaks,border=NA,col=coltab,main="",axes=F,add=T)
plot(bord,add=T,lwd=2)
color.legend(1.5,66.0,3.0,72.0,rect.col=coltab,legend=lab,gradient="Y",align="rb",cex=1.5)
if (param == "frge25") {
text(25.0,72.5,"vind(100 m) > 25 m/s [t/aar]",cex=1.2,font=2)
}
if (param == "frlt4") {
text(25.0,72.5,"vind(100 m) < 4 m/s [%]",cex=1.2,font=2)
}

dev.off()

# end loop over indices
 }

