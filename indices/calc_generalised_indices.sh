#!/bin/bash

##!/usr/bin/bash   # <- use this on Lustre
set -e #exit on error
#set -x

#---------------------------------------------------#
#### DESCRIPTION OF SCRIPT ####
## Script to calculate annual and seasonal values for various indices from the bias-adjusted RCM data
# EQM and 3DBC
# Hist, rcp26 and rcp45 so far, ssp3-7.0 and seNorge to follow
#
## Call: 
#  ./calc_generalised_indices.sh --var VAR --refbegin 1991 --refend 2020 --scenbegin 2071 --scenend 2100 --rcm modelA,modelB,modelC,etc.
#  where VAR is one of hurs, pr, ps, rlds, rsds, sfcWind, tas, tasmax; later also mrro (runoff), swe (snow), esvpbls (evapotranspiration), soilmoist (soil moisture deficit)
#  and reference and scenario begin and end years are set using the corresponding arguments.
#  A selection of RCMs can be made using --rcm followed by a list of RCMs separated by comma (no space between).
#  For additional status messages you may use --verbose.
#
## Output indices:
#  - from tas: tas_annual_mean, tas_seaonal_mean, and more 
#  - from tasmax: more to come (dtr, dzc, fd, norheatwave, norsummer, summerdays, tasmax, tasmin, tropnight).  
#  - from tasmin: same as tasmax
#
## Structure:
#  (1) Global constants, including variables that can be changed by optional user arguments
#  (2) Functions
#  (3) Main script. 
#---------------------------------------------------#



#---------------------------------------------------#
#### (1) GLOBAL CONSTANTS ####

## PATHS ##:
if [ $HOSTNAME == "l-klima-app05" ]; then      # if DISK="hmdata"
	echo ""
	echo "Running from " $HOSTNAME
	WORKDIR=/hdata/hmdata/KiN2100/analyses/indicators/calc_gen_indices/
	IFILEDIR_EQM=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/eqm/netcdf
	IFILEDIR_3DBC=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/3dbc-eqm/netcdf
	IFILEDIR_SENORGE=/hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf
	LANDMASK=/hdata/hmdata/KiN2100/analyses/github/KiN2100/geoinfo/kss2023_mask1km_norway.nc4 # from our github repo
	INIFILE="config_for_calc_generalised_indices.ini" # Config file with metadata to be added to the final nc-files. 
elif [ $HOSTNAME == "lustre" ]; then
	echo ""
	echo "Running from " $HOSTNAME
	WORKDIR=/lustre/storeC-ext/users/kin2100/NVE/analyses/calc_indices/ #
	IFILEDIR_EQM=/lustre/storeC-ext/users/kin2100/NVE/EQM/  # $RCM/$VAR/hist/
	IFILEDIR_3DBC=/lustre/storeC-ext/users/kin2100/MET/3DBC/application/ #$RCM/$VAR/hist/
	#IFILEDIR_SENORGE=/lustre/storeA/project/metkl/senorge2/archive/seNorge_2018_v20_05 # <- check filepath! 
	LANDMASK=/lustre/storeC-ext/users/kin2100/NVE/analyses/kss2023_mask1km_norway.nc4
	INIFILE="config_for_calc_generalised_indices.ini" # Config file with metadata to be added to the final nc-files. 
else
	echo ""
	echo "Currently, the script can be run from hosts l-klima-app05 (NVE) and lustre (MET)."
	echo "Please change host to one of the two, and re-run the script."
	exit
fi
CURRDIR=$PWD #Save current path for return point

echo "Current directory: " $CURRDIR
echo "Working directory: " $WORKDIR

## CONSTANTS THAT CAN BE USER INPUT ##
# Default values (used if not specified by the input arguments):
RCMLIST=("cnrm-r1i1p1-aladin" "ecearth-r12i1p1-cclm") # list of RCMs (available for EQM). Can also be hard coded, e.g. RCMLIST=("cnrm-r1i1p1-aladin" "ecearth-r12i1p1-cclm")
REFBEGIN=2000  #1991
REFEND=2001    #2020
SCENBEGIN=2087 #2071
SCENEND=2088   #2100
VERBOSE=0
VAR=pr

# Change values based on user input:
args=( )
while (( $# )); do
	case $1 in
		--var)       VAR=$2 ;;
		--refbegin)  REFBEGIN=$2 ;;
		--refend)    REFEND=$2 ;;
		--scenbegin) SCENBEGIN=$2 ;;
		--scenend)   SCENEND=$2 ;;
		--rcm)  RCMLIST=$(echo $2 | tr ',' '\n'); RCMLIST=($RCMLIST);; # change from comma to space as separator
		--verbose)   VERBOSE=1 ;;
		-*) printf 'Unknown option: %q\n\n' "$1"
			exit 1 ;; # Aborts when called with unsupported arguments.
		*)  args+=( "$1" ) ;;
	esac
	shift
done

## LISTS OF VALID ITEMS IN CONSTANTS ##
VALID_RCMS=`ls $IFILEDIR_EQM` # list of RCMs (available for EQM). Can also be hard coded, e.g. RCMLIST=("cnrm-r1i1p1-aladin" "ecearth-r12i1p1-cclm")
VALID_REFBEGINS=$( seq 1961 2020 )
VALID_REFENDS=$( seq 1961 2020 )
VALID_SCENBEGINS=$( seq 2021 2100 )
VALID_SCENENDS=$( seq 2021 2100 )
VALID_VARS="tas pr" # later: "hurs pr ps rlds rsds sfcWind tas tasmax mrro swe esvpbls soilmoist"

#---------------------------------------------------#



#---------------------------------------------------#
#### (2) FUNCTIONS ####

function list_include_item {
	# Function that checks if list ($1) contains item ($2) with name ($3)
	# Exits the script if item is not in list.
	local list="$1"
	local item="$2"
	local name="$3"
	if ! [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
		echo ""
		echo "Error: $item is not a valid input of --$name."
		echo "   Please select $name from list: "
		echo "   " ${list[@]}
		exit
	fi
}


function ProgressBar {
	# ProgressBar function (from https://github.com/fearside/ProgressBar/)
	# to show the current progress while running
	# Input is currentState($1) and totalState($2)
	# Process data
	let _progress=(${1}*100/${2}*100)/100
	let _done=(${_progress}*4)/10
	let _left=40-$_done
	# Build progressbar string lengths
	_fill=$(printf "%${_done}s")
	_empty=$(printf "%${_left}s")

	# Build progressbar strings and print the ProgressBar line
	# Output example:                           
	# Progress : [########################################] 100%
	printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}


function get_filenamestart {
    # Function to remove year and fileformat of filename
    # $1 = filename (basename)
    # $2 = year of file
    #
    # E.g. 
    #   $1 = "cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_1992.nc4"
    #   $2 = 1992
    #   output = "cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_"
    filestart=`echo $1 | cut -d "." -f 1` # delete everything in string from (including) "."
    filestart=`echo $filestart | sed s/_$2/_/`   # replace _year with _ in string (added underscore to avoid issue with 2018 and 2005 due to those numbers included elsewhere in filename "*sn2018v2005*")

}


function calc_indices {       
	# Function to calculate indices derived from variable $VAR from $RCM, for each year in period ($REFBEGIN-$REFEND for hist and $SCENBEGIN-$SCENEND for future)
	# reads daily data of variable $VAR, one file per year
	# makes indices derived from $VAR, one file per year 
	# call this function with one input argument: filedir 
    # on the form /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/
    # or          /hdata/hmdata/KiN2100/ForcingData/BiasAdjust/eqm/netcdf/cnrm-r1i1p1-aladin/tas/rcp26/ 
    # I tried adding two input arguments:  filedir and $LANDMASK, but that did not work.
    local count=0
    local filedir=$1
    
    echo "Filedir = " $filedir
    local filelist=`ls $1`  # This is the original line. Roll back to it!
    # filelist=`ls $1/$VAR*`   # testing senorge ls senorgepath/tx*
    # lists files on the form $RCM_rcp26_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_2100.nc4
    #local nbrfiles=`echo $filelist | wc -w`
    let nbrfiles=$(( $REFEND-$REFBEGIN+1 ))
    echo $nbrfiles
    #    $IFILEDIR_EQM/$RCM/$VAR/hist/
        
    echo "Processing " $1
    # echo "Processing " $nbrfiles " files"
    # echo "LANDMASK = " $LANDMASK
    

    

    local scenario=`basename $1`
    echo $scenario
    
    if [ $scenario == "hist" ]; then # | [ $period == "senorge" ]
		firstyear=$REFBEGIN
		lastyear=$REFEND
    elif [ $scenario == "rcp26" ] || [ $scenario == "rcp45" ]; then
		firstyear=$SCENBEGIN
		lastyear=$SCENEND
    else
		echo "check if you are computing the right thing."
    fi
	
	ofilestartlist=""
	
    for yyyy in $( seq $firstyear $lastyear )   # list chosen years.
    do
		file=`ls "$1"/*$yyyy.nc4`      # cannot be "local".
		local file=`basename $file`                   
		echo "Ifile is: " $file
		local ofile=`echo $file | sed s/daily_//`
		echo "Ofile is: " $ofile

		if [ $VAR == "tas" ]; then
			echo ""
			echo "tas chosen. Now processing ifile " $file ", which is number " $(( $count+1 )) " out of " $nbrfiles " (from one model, RCM and RCP only)."
			
			## For each index: Make ofilenames by substituting _varname_ (here: _tas_) with _indexname_ (potentially with time resolution)
			local ofile_tas_annual=`echo $ofile | sed s/_tas_/_tas_annual_/`                   # mean temperature
			local ofile_tas_seasonal=`echo $ofile | sed s/_tas_/_tas_seasonal_/`               # mean temperature
			local ofile_degday17le_annual=`echo $ofile | sed s/_tas_/_degday17le_annual_/`     # Mean annual heating degree-day (tas<17 °C)
			local ofile_gsl_annual=`echo $ofile | sed s/_tas_/_gsl_annual_/`                   # Mean annual growing season length (days tas >=5 °C)
			local ofile_degday5ge_annual=`echo $ofile | sed s/_tas_/_degday5ge_annual_/`       # Growing degree day (tas >5 °C)
			local ofile_degday22ge_annual=`echo $ofile | sed s/_tas_/_degday22ge_annual_/`     # Cooling degree day (tas>=22 °C)
			#-# NEW INDEX from tas? Add line (as above) here #-#

			## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_tas_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_tas_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_degday17le_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_gsl_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_degday5ge_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_degday22ge_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				#-# NEW INDEX from tas? Add two lines (as above) here #-#
			fi


			# Compute tas_annual
			if ! [ -f ./$RCM/$VAR/$ofile_tas_annual ]; then   # check that the file does not exist
				cdo timmean $filedir/$file  ./$RCM/$VAR/$ofile_tas_annual
				#ncrename -v tas,tas ./$RCM/$VAR/$ofile_tas_annual #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation of tas_annual from daily data, because ofile already exists for year " $yyyy
			fi
	    
			# Compute tas_seasonal
 			if ! [ -f ./$RCM/$VAR/$ofile_tas_seasonal ]; then
				cdo -L yseasmean $filedir/$file ./$RCM/$VAR/$ofile_tas_seasonal
				## ncrename -v tas,tas ./$RCM/$VAR/$ofile_tas_seasonal ./$RCM/$VAR/$ofile_tas_seasonal	 
			else
				echo "Skip computation of tas_seasonal from daily data, because ofile already exists for year " $yyyy
			fi 

			# Compute degday17le_annual, energigradtall
 			if ! [ -f ./$RCM/$VAR/$degday17le_annual ]; then
				## ! ## NEED INPUT FROM OLE-EINAR: cdo -L ???? $filedir/$file ./$RCM/$VAR/$degday17le_annual
				ncrename -v tas,degday17le ./$RCM/$VAR/$degday17le_annual ./$RCM/$VAR/$degday17le_annual	 
			else
				echo "Skip computation of degday17le_annual from daily data, because ofile already exists for year " $yyyy
			fi 

			# Compute gsl_annual, vekstsesong
 			if ! [ -f ./$RCM/$VAR/$gsl_annual ]; then
				## ! ## NEED INPUT FROM OLE-EINAR: cdo -L ???? $filedir/$file ./$RCM/$VAR/$gsl_annual
				ncrename -v tas,gsl ./$RCM/$VAR/$gsl_annual ./$RCM/$VAR/$gsl_annual	 
			else
				echo "Skip computation of gsl_annual from daily data, because ofile already exists for year " $yyyy
			fi 

			# Compute degday5ge_annual, vekstgraddager
 			if ! [ -f ./$RCM/$VAR/$degday5ge_annual ]; then
				## ! ## NEED INPUT FROM OLE-EINAR: cdo -L ???? $filedir/$file ./$RCM/$VAR/$degday5ge_annual
				ncrename -v tas,degday5ge ./$RCM/$VAR/$degday5ge_annual ./$RCM/$VAR/$degday5ge_annual	 
			else
				echo "Skip computation of degday5ge_annual from daily data, because ofile already exists for year " $yyyy
			fi 

			# Compute degday22ge_annual, avkjolingsgraddager
 			if ! [ -f ./$RCM/$VAR/$degday22ge_annual ]; then
				## ! ## NEED INPUT FROM OLE-EINAR: cdo -L ???? $filedir/$file ./$RCM/$VAR/$degday22ge_annual
				ncrename -v tas,degday22ge ./$RCM/$VAR/$degday22ge_annual ./$RCM/$VAR/$degday22ge_annual	 
			else
				echo "Skip computation of degday22ge_annual from daily data, because ofile already exists for year " $yyyy
			fi 

			#-# NEW INDEX from tas? Add the if-block with cdo-command and ncrename (as above) here #-#
	 


		# elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ] || [ $VAR == "tx" ] || [ $VAR == "tn" ]; then   # Testing senorge
		elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ]; then
			echo ""
			echo "tasmax or tasmin chosen. Now processing ifile " $file ", which is number " $(( $count+1 )) " out of " $nbrfiles " (from one model, RCM and RCP only)."
			echo "First computing indices based on both tasmin and tasmax."

			## For each index: Make ofilenames by substituting _varname_ with _indexname_ (potentially with time resolution)
			local ofile_dtr_annual=`echo $ofile | sed s/_$VAR_/_dtr_annual_/`         #diurnal temperature range annual
			local ofile_dtr_seasonal=`echo $ofile | sed s/_$VAR_/_dtr_seasonal_/`     #diurnal temperature range seasonal
			local ofile_dzc_annual=`echo $ofile | sed s/_tasmax_/_dzc_annual_/`       #number of days with zero-crossing
			local ofile_dzc_seasonal=`echo $ofile | sed s/_tasmax_/_dzc_seasonal_/`   #number of days with zero-crossing
			#-# NEW INDEX from both tasmin and tasmax? Add line (as above) here #-#

			## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_dtr_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_dtr_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_dzc_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_dzc_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				#-# NEW INDEX from both tasmin and tasmax? Add two lines (as above) here #-#
			fi

			# Read in the extra variable needed (tasmin if user chose tasmax and vixe versa):
			if [ $VAR == "tasmax" ]; then
				local ifile_tasmax=$ifile
				local ifiledir_tasmax=$ifiledir
				local ifile_tasmin=`echo $file_tasmax | sed s/_tasmax_/_tasmin_/`
				local ifiledir_tasmin=`echo $filedir_tasmax | sed s/_tasmax_/_tasmin_/`
			else
				local ifile_tasmin=$ifile
				local ifiledir_tasmin=$ifiledir
				local ifile_tasmax=`echo $file_tasmin | sed s/_tasmin_/_tasmax_/`
				local ifiledir_tasmax=`echo $filedir_tasmin | sed s/_tasmin_/_tasmax_/`
				mkdir -p $RCM/tasmax #make tasmax folder here because indices based on both tasmin and tasmax are stored in the folder of tasmax
			fi

			# Compute dtr_annual, diurnal temperature range
			if ! [ -f ./$RCM/tasmax/$ofile_dtr_annual ]; then   # check if the file exists
				echo "Ofile_dtr=" $RCM"/dtr/"$ofile_dtr	 
				cdo -L timmean -sub  $filedir_tasmax/$file_tasmax $ifiledir_tasmin/$ifile_tasmin ./$RCM/tasmax/$ofile_dtr_annual
				ncrename -v $VAR,dtr ./$RCM/tasmax/$ofile_dtr_annual ./$RCM/tasmax/$ofile_dtr_annual	 
			else
				echo "Skip computation of dtr_annual from daily data, because ofile already exists for year " $yyyy
			fi

			# Compute dtr_seasonal, diurnal temperature range
			if ! [ -f ./$RCM/tasmax/$ofile_dtr_seasonal ]; then   # check if the file exists
				cdo -L yseasmean -sub  $filedir_tasmax/$file_tasmax $ifiledir_tasmin/$ifile_tasmin ./$RCM/tasmax/$ofile_dtr_seasonal
				ncrename -v $VAR,dtr ./$RCM/tasmax/$ofile_dtr_seasonal ./$RCM/tasmax/$ofile_dtr_seasonal	 
			else
				echo "Skip computation of dtr_seasonal from daily data, because ofile already exists for year " $yyyy
			fi

	 	 
			# Compute dzc_annual, zero-crossing
			if ! [ -f ./$RCM/tasmax/$ofile_dzc_annual ]; then   # check if the file exists
				cdo -L timsum -mul -ltc,273.15  $ifiledir_tasmin/$ifile_tasmin -gtc,273.15  $filedir_tasmax/$file_tasmax ./$RCM/tasmax/$ofile_dzc_annual
				ncrename -v $VAR,dzc ./$RCM/tasmax/$ofile_dzc_annual ./$RCM/tasmax/$ofile_dzc_annual	 
			else
				echo "Skip computation of dzc_annual from daily data, because ofile already exists for year " $yyyy
			fi

			# Compute dzc_seasonal, zero-crossing
			if ! [ -f ./$RCM/tasmax/$ofile_dzc_seasonal ]; then   # check if the file exists
				cdo -L yseassum -mul -ltc,273.15  $ifiledir_tasmin/$ifile_tasmin -gtc,273.15  $filedir_tasmax/$file_tasmax ./$RCM/tasmax/$ofile_dzc_seasonal
				ncrename -v $VAR,dzc ./$RCM/tasmax/$ofile_dzc_seasonal ./$RCM/tasmax/$ofile_dzc_seasonal	 
			else
				echo "Skip computation of dzc_seasonal from daily data, because ofile already exists for year " $yyyy
			fi



			if [ $VAR == "tasmax" ]; then
				echo "Next computing indices based on tasmax."
				
				## For each index: Make ofilenames by substituting _varname_ (here: _tasmax_) with _indexname_ (potentially with time resolution)
				local ofile_tasmax_annual=`echo $ofile | sed s/_tasmax_/_tasmax_annual_/`           #mean tasmax
				local ofile_tasmax_seasonal=`echo $ofile | sed s/_tasmax_/_tasmax_seasonal_/`	 
				local ofile_tasmax20ge_annual=`echo $ofile | sed s/_tasmax_/_tasmax20ge_annual_/`   #number of summer days
				local ofile_norheatwave_annual=`echo $ofile | sed s/_tasmax_/_norheatwave_annual_/` #nordic heat wave index events

				## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
				if [ $count == 0 ]; then
					get_filenamestart $ofile_tasmax_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_tasmax_seasonal $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_tasmax20ge_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_norheatwave_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"

					#-# NEW INDEX from tas? Add two lines (as above) here #-#
				fi

				# Compute tasmax_annual
				if ! [ -f ./$RCM/$VAR/$ofile_tasmax_annual ]; then   # check that the file does not exist
					cdo timmean $filedir/$file  ./$RCM/$VAR/$ofile_tasmax_annual
					#ncrename -v tasmax,tasmax ./$RCM/$VAR/$ofile_tasmax_annual #https://linux.die.net/man/1/ncrename    #comment out when no change in varname
				else
					echo "Skip computation of tasmax_annual from daily data, because ofile already exists for year " $yyyy
				fi
			
				# Compute tasmax_seasonal
				if ! [ -f ./$RCM/$VAR/$ofile_tasmax_seasonal ]; then
					cdo -L yseasmean $filedir/$file ./$RCM/$VAR/$ofile_tasmax_seasonal
					## ncrename -v tasmax,tasmax ./$RCM/$VAR/$ofile_tasmax_seasonal ./$RCM/$VAR/$ofile_tasmax_seasonal	 #comment out when no change in varname
				else
					echo "Skip computation of tasmax_seasonal from daily data, because ofile already exists for year " $yyyy
				fi 
				
				# Compute tasmax20ge, i.e. nordic summerdays (tasmax>=20 degC), nordiske sommerdager
				if ! [ -f ./$RCM/$VAR/$ofile_tasmax20ge_annual ]; then   # check if the file exists
					cdo -L timsum -gec,293.15  $filedir/$file ./$RCM/$VAR/$ofile_tasmax20ge_annual
					ncrename -v tasmax,tasmax20ge ./$RCM/$VAR/$ofile_tasmax_seasonal ./$RCM/$VAR/$ofile_tasmax20ge_annual	 
				else
					echo "Skip computation of tasmax20ge_annual from daily data, because ofile already exists for year " $yyyy
				fi 

				# Compute norheatwave_annual, norsk hetebølge, five consecutive days with tasmax>=27 degC
				if ! [ -f ./$RCM/$VAR/$ofile_norheatwave_annual ]; then   # check if the file exists
					cdo -L timsum -eqc,5 -runmean,5 -gec,300.15  $filedir/$file ./$RCM/$VAR/$ofile_norheatwave_annual 
					ncrename -v tasmax,norheatwave ./$RCM/$VAR/$ofile_norheatwave_annual ./$RCM/$VAR/$ofile_norheatwave_annual	 
				else
					echo "Skip computation of norheatwave_annual from daily data, because ofile already exists for year " $yyyy
				fi  
				#-# NEW INDEX from tasmax? Add the if-block with cdo-command and ncrename (as above) here #-#
			fi



			if [ $VAR == "tasmin" ]; then
				echo "Next computing indices based on tasmin."
				
				## For each index: Make ofilenames by substituting _varname_ (here: _tasmin_) with _indexname_ (potentially with time resolution)
				local ofile_tasmin_annual=`echo $ofile | sed s/_tasmin_/_tasmin_annual_/` #mean tasmin
				local ofile_tasmin_seasonal=`echo $ofile | sed s/_tasmin_/_tasmin_seasonal_/` #mean tasmin	 
				local ofile_fd_annual=`echo $ofile | sed s/_tasmin_/_fd_annual_/` #number of frost days
				local ofile_tasmin20le_annual=`echo $ofile | sed s/_tasmin_/_tasmin20le_annual_/` #number of tropical nights

				## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
				if [ $count == 0 ]; then
					get_filenamestart $ofile_tasmin_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_tasmin_seasonal $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_fd_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					
					get_filenamestart $ofile_tasmin20le_annual $yyyy
					ofilestartlist="$ofilestartlist $filestart"
					

					#-# NEW INDEX from tas? Add two lines (as above) here #-#
				fi
			
				# Compute tasmin_annual
				if ! [ -f ./$RCM/$VAR/$ofile_tasmin_annual ]; then
					cdo timmean $filedir/$file  ./$RCM/$VAR/$ofile_tasmin_annual
					#ncrename -v tasmin,tasmin ./$RCM/$VAR/$ofile_tasmin_annual #https://linux.die.net/man/1/ncrename
				else
					echo "Skip computation of tasmin_annual from daily data, because ofile already exists for year " $yyyy
				fi
			
				# Compute tasmin_seasonal
				if ! [ -f ./$RCM/$VAR/$ofile_tasmin_seasonal ]; then
					cdo -L yseasmean $filedir/$file ./$RCM/$VAR/$ofile_tasmin_seasonal
					## ncrename -v tasmin,tasmin ./$RCM/$VAR/$ofile_tasmin_seasonal ./$RCM/$VAR/$ofile_tasmin_seasonal	 
				else
					echo "Skip computation of tasmin_seasonal from daily data, because ofile already exists for year " $yyyy
				fi 

				# Compute fd_annual, number of frost days (tasmin<=0 degC)
				if ! [ -f ./$RCM/$VAR/$ofile_fd_annual ]; then
					cdo -L timsum -ltc,273.15 $filedir/$file ./$RCM/$VAR/$ofile_fd_annual
					ncrename -v tasmin,fd ./$RCM/$VAR/$ofile_fd_annual ./$RCM/$VAR/$ofile_fd_annual	 
				else
					echo "Skip computation of fd_annual from daily data, because ofile already exists for year " $yyyy
				fi

				# Compute tasmin20le_annual, tropenattdøgn, tasmin >= 20 grader
				if ! [ -f ./$RCM/$VAR/$tasmin20le_annual ]; then
					cdo -L timsum -gec,293.15  $filedir/$file ./$RCM/$VAR/$tasmin20le_annual
					ncrename -v tasmin,tasmin20le ./$RCM/$VAR/$tasmin20le_annual ./$RCM/$VAR/$tasmin20le_annual	 
				else
					echo "Skip computation of tasmin20le_annual from daily data, because ofile already exists for year " $yyyy
				fi

				#-# NEW INDEX from tasmin? Add the if-block with cdo-command and ncrename (as above) here #-#
			fi

		

		elif [ $VAR == "pr" ]; then
			echo ""
			echo "pr chosen. Now processing ifile " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."

			## For each index: Make ofilenames by substituting _varname_ (here: _pr_) with _indexname_ (potentially with time resolution)
			local ofile_prsum_annual=`echo $ofile | sed s/_pr_/_prsum_annual_/` # sum of pr over year
			local ofile_prsum_seasonal=`echo $ofile | sed s/_pr_/_prsum_seasonal_/` #sum of pr over seasons 
			local ofile_pr01mm_annual=`echo $ofile | sed s/_pr_/_pr01mm_annual_/`
			local ofile_pr01mm_seasonal=`echo $ofile | sed s/_pr_/_pr01mm_seasonal_/`
			local ofile_pr1mm_annual=`echo $ofile | sed s/_pr_/_pr1mm_annual_/`
			local ofile_pr1mm_seasonal=`echo $ofile | sed s/_pr_/_pr1mm_seasonal_/`
			local ofile_sdii_annual=`echo $ofile | sed s/_pr_/_sdii_annual_/`
			local ofile_sdii_seasonal=`echo $ofile | sed s/_pr_/_sdii_seasonal_/`
			local ofile_pr20mm_annual=`echo $ofile | sed s/_pr_/_pr20mm_annual_/`
			local ofile_pr20mm_seasonal=`echo $ofile | sed s/_pr_/_pr20mm_seasonal_/`
			local ofile_prmax5day=`echo $ofile | sed s/_pr_/_prmax5day_/`
			local ofile_pr95p_annual=`echo $ofile | sed s/_pr_/_pr95p_annual_/`            # Dager med pr > 95-persentilen av døgnmengder (i referanseperioden)
			local ofile_pr95p_seasonal=`echo $ofile | sed s/_pr_/_pr95p_seasonal_/`
			local ofile_pr95ptot_annual=`echo $ofile | sed s/_pr_/_pr95ptot_annual_/`      # Andel (%) dager med PR>95-persentilen av døgnmengde (veldig våte dager)
			local ofile_pr95ptot_seasonal=`echo $ofile | sed s/_pr_/_pr95ptot_seasonal_/`
			local ofile_pr997p_annual=`echo $ofile | sed s/_pr_/_pr997p_annual_/`          # Antall dager pr. år i scenario-periodene med døgnnedbør> 99,7 persentilen for kontrollperioden
			local ofile_pr997p_seasonal=`echo $ofile | sed s/_pr_/_pr997p_seasonal_/`
			local ofile_pr997_annual=`echo $ofile | sed s/_pr_/_pr997_annual_/`            # 99,7 persentil for døgnverdi (mm)
			local ofile_pr997_seasonal=`echo $ofile | sed s/_pr_/_pr997_seasonal_/`

			

			#-# NEW INDEX from pr? Add line (as above) here #-#

			## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_prsum_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_prsum_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr01mm_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr01mm_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr1mm_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr1mm_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_sdii_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_sdii_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr20mm_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr20mm_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_prmax5day $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr95p_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr95p_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr95ptot_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr95ptot_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_pr997p_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				get_filenamestart $ofile_pr997p_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				# NOT INCLUDE THESE NOW, BECAUSE FINAL CALCULATIONS ARE DONE IN THIS FUNCTION AND NOT OUTSIDE AS THE OTHERS.
				# get_filenamestart $ofile_pr997_annual $yyyy
				# ofilestartlist="$ofilestartlist $filestart"

				# get_filenamestart $ofile_pr997_seasonal $yyyy
				# ofilestartlist="$ofilestartlist $filestart"

				#-# NEW INDEX from pr? Add two lines (as above) here #-#
			fi

			# Compute prsum_annual
			if ! [ -f ./$RCM/$VAR/$ofile_prsum_annual ]; then   # check if the file exists
				cdo timsum  $filedir/$file ./$RCM/$VAR/$ofile_prsum_annual
				ncrename -v pr,prsum ./$RCM/$VAR/$ofile_prsum_annual #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation from daily data, because ofile already exists for" "prsum_annual" $yyyy
			fi

			# Compute prsum_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_prsum_seasonal ]; then   # check if the file exists
				cdo -L yseassum  $filedir/$file ./$RCM/$VAR/$ofile_prsum_seasonal
				ncrename -v pr,prsum ./$RCM/$VAR/$ofile_prsum_seasonal #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation from daily data, because ofile already exists for" "prsum_seasonal" $yyyy
			fi
	 

			# Compute pr01mm_annual
			if ! [ -f ./$RCM/$VAR/$ofile_pr01mm_annual ]; then   # check if the file exists
				cdo -L yearsum -gtc,0.1 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr01mm_annual
				ncrename -v pr,pr01mm ./$RCM/$VAR/$ofile_pr01mm_annual
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr01mm_annual" $yyyy
			fi

			# Compute pr01mm_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_pr01mm_seasonal ]; then   # check if the file exists
				cdo -L seassum -gtc,0.1 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr01mm_seasonal
				ncrename -v pr,pr01mm ./$RCM/$VAR/$ofile_pr01mm_seasonal
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr01mm_seasonal" $yyyy
			fi

			# Compute pr1mm_annual
			if ! [ -f ./$RCM/$VAR/$ofile_pr1mm_annual ]; then   # check if the file exists
				cdo -L yearsum -gec,1 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr1mm_annual
				ncrename -v pr,pr1mm ./$RCM/$VAR/$ofile_pr1mm_annual
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr1mm_annual" $yyyy
			fi

			# Compute pr1mm_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_pr1mm_seasonal ]; then   # check if the file exists
				cdo -L seassum -gec,1 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr1mm_seasonal
				ncrename -v pr,pr1mm ./$RCM/$VAR/$ofile_pr1mm_seasonal
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr1mm_seasonal" $yyyy
			fi

			# Compute sdii_annual
			if ! [ -f ./$RCM/$VAR/$ofile_sdii_annual ]; then   # check if the file exists
				cdo -L yearmean -setctomiss,0 -expr,"sdii=pr*(pr>=1)" -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_sdii_annual
				#ncrename -v pr,sdii ./$RCM/$VAR/$ofile_sdii_annual #endres i expr over
			else
				echo "Skip computation from daily data, because ofile already exists for" "sdii_annual" $yyyy
			fi

			# Compute sdii_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_sdii_seasonal ]; then   # check if the file exists
				cdo -L seasmean -setctomiss,0 -expr,"sdii=pr*(pr>=1)" -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_sdii_seasonal
				#ncrename -v pr,sdii ./$RCM/$VAR/$ofile_sdii_seasonal #endres i expr over
			else
				echo "Skip computation from daily data, because ofile already exists for" "sdii_seasonal" $yyyy
			fi

			# Compute pr20mm_annual
			if ! [ -f ./$RCM/$VAR/$ofile_pr20mm_annual ]; then   # check if the file exists
				cdo -L yearsum -gec,20 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr20mm_annual
				ncrename -v pr,pr20mm ./$RCM/$VAR/$ofile_pr20mm_annual
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr20mm_annual" $yyyy
			fi

			# Compute pr20mm_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_pr20mm_seasonal ]; then   # check if the file exists
				cdo -L seassum -gec,20 -mulc,86400  $filedir/$file ./$RCM/$VAR/$ofile_pr20mm_seasonal
				ncrename -v pr,pr20mm ./$RCM/$VAR/$ofile_pr20mm_seasonal
			else
				echo "Skip computation from daily data, because ofile already exists for" "pr20mm_seasonal" $yyyy
			fi

			# Compute prmax5day
			if ! [ -f ./$RCM/$VAR/$ofile_prmax5day ]; then   # check if the file exists
				#cdo timsum  $filedir/$file ./$RCM/$VAR/$ofile_prmax5day
				cdo -L runsum,5 -mulc,86400  $filedir/$file ./$RCM/$VAR/temp_prmax5day.nc
				cdo timmax ./$RCM/$VAR/temp_prmax5day.nc ./$RCM/$VAR/$ofile_prmax5day
				rm ./$RCM/$VAR/temp_prmax5day.nc
				ncrename -v pr,prmax5day ./$RCM/$VAR/$ofile_prmax5day
			else
				echo "Skip computation from daily data, because ofile already exists for" "prmax5day" $yyyy
			fi


			# Historical 30-year percentiles (needed for remaining indices) only need to be computed once
			if [ $yyyy == $REFBEGIN ]; then
				# get all years in reference period and add to filenames
				local refperiodstring="$REFBEGIN-$REFEND"
				local refyearlist="$(seq $REFBEGIN $REFEND)"
				local refyeararray=($refyearlist)
				get_filenamestart $file $yyyy #returns filestart needed for next lines
				ifilestart=$filestart
				local ifiles_reference=( "${refyeararray[@]/#/$filedir$ifilestart}" )
				local ifiles_reference="${ifiles_reference[@]/%/.nc4}"

				mergetime_refperiod_file=temp_mergetime_refperiod_$refperiodstring.nc4

				# mergetime and compute timmin and timmax for reference period, and use that to compute percentiles.
				timmin_refperiod_file=temp_timmin_refperiod_$refperiodstring.nc4
				timmax_refperiod_file=temp_timmax_refperiod_$refperiodstring.nc4
				timpctl95_refperiod_file=temp_timpctl95_refperiod_$refperiodstring.nc4
				timpctl997_refperiod_file=temp_timpctl997_refperiod_$refperiodstring.nc4

				if ! [ -f ./$RCM/$VAR/$timpctl95_refperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$mergetime_refperiod_file ]; then
						cdo mergetime $ifiles_reference ./$RCM/$VAR/$mergetime_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmin_refperiod_file ]; then
						cdo timmin ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmin_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmax_refperiod_file ]; then
						cdo timmax ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmax_refperiod_file
					fi
					cdo timpctl,95 ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmin_refperiod_file ./$RCM/$VAR/$timmax_refperiod_file ./$RCM/$VAR/$timpctl95_refperiod_file
				fi

				if ! [ -f ./$RCM/$VAR/$timpctl997_refperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$mergetime_refperiod_file ]; then
						cdo mergetime $ifiles_reference ./$RCM/$VAR/$mergetime_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmin_refperiod_file ]; then
						cdo timmin ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmin_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmax_refperiod_file ]; then
						cdo timmax ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmax_refperiod_file
					fi
					cdo -L -ifthen $LANDMASK -timpctl,99.7 ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$timmin_refperiod_file ./$RCM/$VAR/$timmax_refperiod_file ./$RCM/$VAR/$timpctl997_refperiod_file
				fi


				# Compute yseasmin and yseasmax for reference period, and use that to compute seasonal percentiles.
				yseasmin_refperiod_file=temp_yseasmin_refperiod_$refperiodstring.nc4
				yseasmax_refperiod_file=temp_yseasmax_refperiod_$refperiodstring.nc4
				yseaspctl95_refperiod_file=temp_yseaspctl95_refperiod_$refperiodstring.nc4
				yseaspctl997_refperiod_file=temp_yseaspctl997_refperiod_$refperiodstring.nc4

				if ! [ -f ./$RCM/$VAR/$yseaspctl95_refperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$yseasmin_refperiod_file ]; then
						cdo -L yseasmin ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmin_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$yseasmax_refperiod_file ]; then
						cdo -L yseasmax ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmax_refperiod_file
					fi
					cdo -L -ifthen $LANDMASK -yseaspctl,95 ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmin_refperiod_file ./$RCM/$VAR/$yseasmax_refperiod_file ./$RCM/$VAR/$yseaspctl95_refperiod_file
				fi
				

				if ! [ -f ./$RCM/$VAR/$yseaspctl997_refperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$yseasmin_refperiod_file ]; then
						cdo -L yseasmin ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmin_refperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$yseasmax_refperiod_file ]; then
						cdo -L yseasmax ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmax_refperiod_file
					fi
					cdo -L yseaspctl,99.7 ./$RCM/$VAR/$mergetime_refperiod_file ./$RCM/$VAR/$yseasmin_refperiod_file ./$RCM/$VAR/$yseasmax_refperiod_file ./$RCM/$VAR/$yseaspctl997_refperiod_file
				fi
				echo "Done computing percentiles for reference period" $refperiodstring
			fi
			
			# THIS PART IS DONE FOR EVERY ITERATION
			# Compute pr95p_annual
			if ! [ -f ./$RCM/$VAR/$ofile_pr95p_annual ]; then
				cdo -L timsum -gt $filedir/$file ./$RCM/$VAR/$timpctl95_refperiod_file ./$RCM/$VAR/$ofile_pr95p_annual
				ncrename -v pr,pr95p ./$RCM/$VAR/$ofile_pr95p_annual
			fi

			# Compute pr95p_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_pr95p_seasonal ]; then
				for iseas in 1 2 3 4; do
					if ! [ -f $filedir/seas$iseas\_$file ]; then
						cdo selseas,$iseas $filedir/$file ./$RCM/$VAR/seas$iseas\_$file
					fi
					if ! [ -f ./$RCM/$VAR/seas$iseas\_$ofile_pr95p_seasonal ]; then
						cdo -L timsum -gt ./$RCM/$VAR/seas$iseas\_$file -seltimestep,$iseas ./$RCM/$VAR/$yseaspctl95_refperiod_file ./$RCM/$VAR/seas$iseas\_$ofile_pr95p_seasonal
					fi
				done
				cdo mergetime ./$RCM/$VAR/seas[1-4]_$ofile_pr95p_seasonal ./$RCM/$VAR/$ofile_pr95p_seasonal
				ncrename -v pr,pr95p ./$RCM/$VAR/$ofile_pr95p_seasonal
				rm ./$RCM/$VAR/seas[1-4]_$ofile_pr95p_seasonal
			fi

			# Compute pr997p_annual
			if ! [ -f ./$RCM/$VAR/$ofile_pr997p_annual ]; then
				cdo -L timsum -gt $filedir/$file ./$RCM/$VAR/$timpctl997_refperiod_file ./$RCM/$VAR/$ofile_pr997p_annual
				ncrename -v pr,pr997p ./$RCM/$VAR/$ofile_pr997p_annual
			fi

			# Compute pr997p_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_pr997p_seasonal ]; then
				for iseas in 1 2 3 4; do
					if ! [ -f $filedir/seas$iseas\_$file ]; then
						cdo selseas,$iseas $filedir/$file ./$RCM/$VAR/seas$iseas\_$file
					fi
					if ! [ -f ./$RCM/$VAR/seas$iseas\_$ofile_pr997p_seasonal ]; then
						cdo -L timsum -gt ./$RCM/$VAR/seas$iseas\_$file -seltimestep,$iseas ./$RCM/$VAR/$yseaspctl997_refperiod_file ./$RCM/$VAR/seas$iseas\_$ofile_pr997p_seasonal
					fi
				done
				cdo mergetime ./$RCM/$VAR/seas[1-4]_$ofile_pr997p_seasonal ./$RCM/$VAR/$ofile_pr997p_seasonal
				ncrename -v pr,pr997p ./$RCM/$VAR/$ofile_pr997p_seasonal
				rm ./$RCM/$VAR/seas[1-4]_$ofile_pr997p_seasonal
			fi

			# Compute _pr95ptot_annual
			gt_timpctl95_file=temp_gt_timpctl95_$file
			sumPgt_timpctl95_file=temp_sumPgt_timpctl95_$file
			timsum_year_file=temp_timsum_$file

			if ! [ -f ./$RCM/$VAR/$ofile_pr95ptot_annual ]; then
				cdo gt $filedir/$file ./$RCM/$VAR/$timpctl95_refperiod_file ./$RCM/$VAR/$gt_timpctl95_file #1 if daily_P>perc95, 0 otherwise
				cdo -L yearsum -mul $filedir/$file ./$RCM/$VAR/$gt_timpctl95_file ./$RCM/$VAR/$sumPgt_timpctl95_file #annual P-sum of P>perc95
				cdo yearsum $filedir/$file ./$RCM/$VAR/$timsum_year_file #annual P-sum
				cdo div ./$RCM/$VAR/$sumPgt_timpctl95_file ./$RCM/$VAR/$timsum_year_file ./$RCM/$VAR/$ofile_pr95ptot_annual
				ncrename -v pr,pr95ptot ./$RCM/$VAR/$ofile_pr95ptot_annual
			fi

			# Compute _pr95ptot_seasonal
			gt_yseaspctl95_file=temp_gt_yseaspctl95_$file
			sumPgt_yseaspctl95_file=temp_sumPgt_yseaspctl95_$file
			yseassum_year_file=temp_yseassum_$file

			if ! [ -f ./$RCM/$VAR/$ofile_pr95ptot_seasonal ]; then
				for iseas in 1 2 3 4; do
					if ! [ -f $filedir/seas$iseas\_$file ]; then
						cdo selseas,$iseas $filedir/$file ./$RCM/$VAR/seas$iseas\_$file
					fi
					if ! [ -f ./$RCM/$VAR/seas$iseas\_$gt_yseaspctl95_file ]; then
						cdo -L gt ./$RCM/$VAR/seas$iseas\_$file -seltimestep,$iseas ./$RCM/$VAR/$yseaspctl95_refperiod_file ./$RCM/$VAR/seas$iseas\_$gt_yseaspctl95_file  #1 if daily_P>perc95, 0 otherwise
					fi
				done
				cdo mergetime ./$RCM/$VAR/seas[1-4]_$gt_yseaspctl95_file ./$RCM/$VAR/$gt_yseaspctl95_file
				rm ./$RCM/$VAR/seas[1-4]_$gt_yseaspctl95_file
				cdo -L seassum -mul $filedir/$file ./$RCM/$VAR/$gt_yseaspctl95_file ./$RCM/$VAR/$sumPgt_yseaspctl95_file #seasonal P-sum of P>perc95
				cdo seassum $filedir/$file ./$RCM/$VAR/$yseassum_year_file #seasonal P-sum
				cdo div ./$RCM/$VAR/$sumPgt_yseaspctl95_file ./$RCM/$VAR/$yseassum_year_file ./$RCM/$VAR/$ofile_pr95ptot_seasonal
				ncrename -v pr,pr95ptot ./$RCM/$VAR/$ofile_pr95ptot_seasonal
			fi

			# Compute _pr997_annual and _pr997_seasonal
			# Scenario 30-year percentiles (needed for remaining indices) only need to be computed once for one scenario
			if [ $yyyy == $SCENBEGIN ]; then
				# Merge daily data for all years in scenario period
				local scenperiodstring="$SCENBEGIN-$SCENEND"
				local scenyearlist="$(seq $SCENBEGIN $SCENEND)"
				local scenyeararray=($scenyearlist)
				get_filenamestart $file $yyyy #returns filestart needed for next line
				local ifiles_scenario=( "${scenyeararray[@]/#/$filedir$filestart}" )
				local ifiles_scenario="${ifiles_scenario[@]/%/.nc4}"

				mergetime_scenperiod_file=temp_mergetime_scenperiod_$scenperiodstring.nc4

				# Merge time and compute timmin and timmax for scenario period, and use that to compute percentiles.
				timmin_scenperiod_file=temp_timmin_scenperiod_$scenperiodstring.nc4
				timmax_scenperiod_file=temp_timmax_scenperiod_$scenperiodstring.nc4
				timpctl997_scenperiod_file=temp_timpctl997_scenperiod_$scenperiodstring.nc4

				if ! [ -f ./$RCM/$VAR/$timpctl997_scenperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$mergetime_scenperiod_file ]; then
						cdo mergetime $ifiles_scenario ./$RCM/$VAR/$mergetime_scenperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmin_scenperiod_file ]; then
						cdo timmin ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$timmin_scenperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$timmax_scenperiod_file ]; then
						cdo timmax ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$timmax_scenperiod_file
					fi
					cdo -L -ifthen $LANDMASK -timpctl,99.7 ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$timmin_scenperiod_file ./$RCM/$VAR/$timmax_scenperiod_file ./$RCM/$VAR/$timpctl997_scenperiod_file
				fi

				# Merge time and compute yseasmin and yseasmax for scenario period, and use that to compute seasonal percentiles.
				yseasmin_scenperiod_file=temp_yseasmin_scenperiod_$scenperiodstring.nc4
				yseasmax_scenperiod_file=temp_yseasmax_scenperiod_$scenperiodstring.nc4
				yseaspctl997_scenperiod_file=temp_yseaspctl997_scenperiod_$scenperiodstring.nc4

				if ! [ -f ./$RCM/$VAR/$yseaspctl997_scenperiod_file ]; then
					if ! [ -f ./$RCM/$VAR/$mergetime_scenperiod_file ]; then
						cdo mergetime $ifiles_scenario ./$RCM/$VAR/$mergetime_scenperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$yseasmin_scenperiod_file ]; then
						cdo -L yseasmin ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$yseasmin_scenperiod_file
					fi
					if ! [ -f ./$RCM/$VAR/$yseasmax_scenperiod_file ]; then
						cdo -L yseasmax ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$yseasmax_scenperiod_file
					fi
					cdo -L -ifthen $LANDMASK -yseaspctl,99.7 ./$RCM/$VAR/$mergetime_scenperiod_file ./$RCM/$VAR/$yseasmin_scenperiod_file ./$RCM/$VAR/$yseasmax_scenperiod_file ./$RCM/$VAR/$yseaspctl997_scenperiod_file
				fi

				#Compute change from reference period 99.7 percentile here or later on? Not same procedure as other because not annually resolved. Currently added here.
				#   annual
				ofile_timpctl997_scen_vs_hist=test_ofile_timpctl997_scen_vs_hist.nc4
				cdo -L -mulc,100 -div -sub ./$RCM/$VAR/$timpctl997_scenperiod_file ./$RCM/$VAR/$timpctl997_refperiod_file ./$RCM/$VAR/$timpctl997_refperiod_file $ofile_timpctl997_scen_vs_hist
				ncrename -v pr,pr997 $ofile_timpctl997_scen_vs_hist
				add_attributes_to_file $ofile_timpctl997_scen_vs_hist
				ncatted -O -a units,$indexname,o,c,"%" $ofile_timpctl997_scen_vs_hist
				
				#   seasonal
				ofile_yseaspctl997_scen_vs_hist=test_ofile_yseaspctl997_scen_vs_hist.nc4
				cdo -L -mulc,100 -div -sub ./$RCM/$VAR/$yseaspctl997_scenperiod_file ./$RCM/$VAR/$yseaspctl997_refperiod_file ./$RCM/$VAR/$yseaspctl997_refperiod_file $ofile_yseaspctl997_scen_vs_hist
				ncrename -v pr,pr997 $ofile_yseaspctl997_scen_vs_hist
				add_attributes_to_file $ofile_yseaspctl997_scen_vs_hist
				ncatted -O -a units,$indexname,o,c,"%" $ofile_timpctl997_scen_vs_hist
			fi
			#exit
	 
			#-# NEW INDEX from pr? Add the if-block with cdo-command and ncrename (as above) here #-#
			#-# crop domain to mainland Norway by "-ifthen $LANDMASK" (as above) #-#


		# elif [ $VAR == "hurs" ]; then
			# 	 echo ""
			#    echo "hurs chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_hurs_monmean=`echo $ofile | sed s/_hurs_/_hurs_monmean_/`	 

			# 	 # Monthly mean av hurs
			#    cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_hurs_monmean	 

			# 	 ncatted -O -a short_name,hurs,o,c,"hurs_monmean" 		                ./$RCM/$VAR/$ofile_hurs_monmean	 
			# 	 ncatted -O -a units,hurs,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_hurs_monmean
			# 	 ncatted -O -a long_name,hurs,o,c,"surface_downwelling_shortwave_flux_in_air"	./$RCM/$VAR/$ofile_hurs_monmean


		# elif [ $VAR == "rlds" ]; then
			# 	 echo ""
			#    echo "rlds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rlds_monmean=`echo $ofile | sed s/_rlds_/_rlds_monmean_/`	 
			
			# 	 # Monthly mean av rlds
			#    cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_rlds_monmean	 
			
			# 	 ncatted -O -a short_name,rlds,o,c,"rlds_monmean"                  	        ./$RCM/$VAR/$ofile_rlds_monmean	 
			# 	 ncatted -O -a units,rlds,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_rlds_monmean
			# 	 ncatted -O -a long_name,rlds,o,c,"surface_downwelling_longwave_flux_in_air"	./$RCM/$VAR/$ofile_rlds_monmean


		#  elif [ $VAR == "rsds" ]; then
			# 	 echo ""
			#    echo "rsds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rsds_monmean=`echo $ofile | sed s/_rsds_/_rsds_monmean_/`	 
			
			# 	 # Monthly mean av rsds
			#    cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_rsds_monmean	 
			
			# 	 ncatted -O -a short_name,rsds,o,c,"rsds_monmean"         ./$RCM/$VAR/$ofile_rsds_monmean	 
			# 	 ncatted -O -a units,rsds,o,c,"%"                         ./$RCM/$VAR/$ofile_rsds_monmean
			# 	 ncatted -O -a long_name,rsds,o,c,"relative humidity"     ./$RCM/$VAR/$ofile_rsds_monmean

			
		#  elif [ $VAR == "ps" ]; then
			# 	 echo ""
			#    echo "ps chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_ps_monmean=`echo $ofile | sed s/_ps_/_ps_monmean_/`	 
			
			# 	 # Monthly mean av ps
			#    cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_ps_monmean	 
			
			# 	 ncatted -O -a short_name,ps,o,c,"ps_monmean" 		./$RCM/$VAR/$ofile_ps_monmean	 
			# 	 ncatted -O -a units,ps,o,c,"Pa" 		        ./$RCM/$VAR/$ofile_ps_monmean
			# 	 ncatted -O -a long_name,ps,o,c,"surface_air_pressure"	./$RCM/$VAR/$ofile_ps_monmean



		#  elif [ $VAR == "sfcWind" ]; then
			# 	 echo ""
			#    echo "sfcWind chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_sfcWind_monmean=`echo $ofile | sed s/_sfcWind_/_sfcWind_monmean_/`	 
			
			# 	 # Monthly mean av sfcWind
			#    cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_sfcWind_monmean	 
			
			# 	 ncatted -O -a short_name,sfcWind,o,c,"sfcWind_monmean" ./$RCM/$VAR/$ofile_sfcWind_monmean	 
			# 	 ncatted -O -a units,sfcWind,o,c,"m s-1" 		./$RCM/$VAR/$ofile_sfcWind_monmean
			# 	 ncatted -O -a long_name,sfcWind,o,c,"wind_speed"	./$RCM/$VAR/$ofile_sfcWind_monmean
			
		fi             # end if VAR

		((count+=1))
		ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
      
	done              # end for file in filelist

   
	echo "Done computing monthly indices and adding metadata for all years in model " $RCM " and variable " $VAR ". Other models and RCPs still remain."

	echo $ofilelist # print $ofilelist (last year)
   
}                    # end function calc_indices


function add_attributes_to_file()
{
    #For input nc-file, extract variable name, get corresponding attributes from ini-file and add to nc-file.
    local chosen_filename=$1
    chosen_indexname=$(cdo showname $chosen_filename) #extract variable name from ncfile (only allow one variable per file)
    chosen_indexname=${chosen_indexname[@]} #removes problem with space that appears in section_name below. Cannot be local.

    ## Add variable attributes to ncfile of $chosen_indexname
    section_name="varattr_$chosen_indexname"
    eval "keys=( \"\${${section_name}_keys[@]}\" )"
    for i in "${!keys[@]}"; do
        local key=${keys[$i]}
        ncatted -O -h -a $key,$chosen_indexname,o,c,"$(get_value $section_name $key)" $chosen_filename #echo "$key:" $(get_value $section_name $key)
    done

    ## Add global attributes to ncfile of $chosen_indexname
    section_name="globattr_$chosen_indexname"
    eval "keys=( \"\${${section_name}_keys[@]}\" )"
    for i in "${!keys[@]}"; do
        local key=${keys[$i]}
        ncatted -O -h -a $key,global,o,c,"$(get_value $section_name $key)" $chosen_filename #echo "$key:" $(get_value $section_name $key)
    done
}

function calc_periodmeans {
    # This function do mergetime and timmean over all selected years for annual indices. It needs several arguments in correct order:
    #   $1 = reffbegin or SCENBEGIN
    #   $2 = REFEND or SCENEND
    #   $remaining = list of each substring common for all files for multiple years for which timmean should be computed
    #       A substring can be e.g. "cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_" (where the year and .nc(4) is removed)
    echo ""
    echo "In function computing mean over period"
    

    # make list of years:
    local period="$1-$2"
    local yearlist="$(seq $1 $2)"
    local yeararray=($yearlist)

    local ifilestartlist=${@:3}
    local ipath=$WORKDIR/$RCM/$VAR/
    local opath=$WORKDIR/tmp/$USER/$RCM/$VAR/
    mkdir -p $opath
    
	ofilelist=""
    # calc period mean for each ifilestart string
    for ifilestart in $ifilestartlist
    do
        local ifilepathlist_periodyears=( "${yeararray[@]/#/$ipath$ifilestart}" )
        local ifilepathlist_periodyears="${ifilepathlist_periodyears[@]/%/.nc4}"

        ofilepath1="$opath$ifilestart${period}_singleyears.nc4"
        ofilepath2="$opath$ifilestart${period}.nc4"
        if ! [ -f $ofilepath1 ]; then   # if ofile not already exist, do mergetime
            cdo mergetime $ifilepathlist_periodyears $ofilepath1
            echo Saved: "$(basename $ofilepath1)"
        fi
        if ! [ -f $ofilepath2 ]; then   # if ofile not already exist, do timmean
			cdo -L yseasmean  -ifthen $LANDMASK $ofilepath1 $ofilepath2 #yseasmean (instead of timmean) makes the mean calculation work for both annual and seasonal data.
            echo Saved: "$(basename $ofilepath2)"
        fi
		add_attributes_to_file $ofilepath2
		rm $ofilepath1
		ofilelist="$ofilelist $ofilepath2"
    done
    echo ""

} 
#---------------------------------------------------#



#---------------------------------------------------#
#### (3) Main script ####


## If --verbose given by user, print input ##
if [ $VERBOSE -eq 1 ]; then
	echo "RCMLIST:   " ${RCMLIST[@]} # first and last are ${RCMLIST[0]} and ${RCMLIST[-1]}
	echo "REFBEGIN:  " $REFBEGIN
	echo "REFEND:    " $REFEND
	echo "SCENBEGIN: " $SCENBEGIN
	echo "SCENEND:   " $SCENEND
fi

## Use function that checks if (user or default) input is in list of valid inputs, and exits script if not ##
list_include_item "$VALID_REFBEGINS" $REFBEGIN 'refbegin'
list_include_item "$VALID_REFENDS" $REFEND 'refend'
list_include_item "$VALID_SCENBEGINS" $SCENBEGIN 'scenbegin'
list_include_item "$VALID_SCENENDS" $SCENEND 'scenend'
list_include_item "$VALID_VARS" $VAR 'var'
for rcm in $RCMLIST
do
	list_include_item "$VALID_RCMS" $rcm 'rcm'
done
echo "Accepted all (default and user) inputs of rcms, periods and variables. Proceed."

# Load files neccessary for metadata
source ini_file_parser.sh # Load in the ini file parser file (https://github.com/DevelopersToolbox/ini-file-parser)
process_ini_file $INIFILE # Load and process the ini/config file

## Make working directory if not exists, go there, and make directory for temporary files if not exists ## 
mkdir -p $WORKDIR
cd $WORKDIR
mkdir -p tmp/$USER



#SENORGE-HIST
### For the historical period (DP1), we need to process seNorge data.
### need to enable calc_indices for seNorge data. (seNorge 2018 v20.05)
### includes making variable names (e.g. tg instead of tas), and potentially other stuff (filenames, paths?) more flexible in calc_indices
### files on the form tg_senorge2018_1957.nc or senorge2018_RR_1957.nc
#calc_indices $IFILEDIR_SENORGE       
#calc_periodmeans $REFBEGIN $REFEND $ofilestartlist # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
#echo "done senorge-hist period means"

for RCM in $RCMLIST
do
	for bias_path in $IFILEDIR_EQM $IFILEDIR_3DBC
	do
		echo -ne "\n\nProcessing" $RCM $VAR "in" $bias_path"\n"
		mkdir -p $RCM/$VAR

		#HIST
		calc_indices $bias_path/$RCM/$VAR/hist/
		calc_periodmeans $REFBEGIN $REFEND $ofilestartlist # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
		ofilelist_hist=($ofilelist)
		echo "done hist period means"

		#RCP2.6
		calc_indices $bias_path/$RCM/$VAR/rcp26/
		calc_periodmeans $SCENBEGIN $SCENEND $ofilestartlist  # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
		ofilelist_rcp26=($ofilelist)
		echo "done rcp2.6 period means"

		#RCP4.5
		calc_indices $bias_path/$RCM/$VAR/rcp45/
		calc_periodmeans $SCENBEGIN $SCENEND $ofilestartlist  # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
		ofilelist_rcp45=($ofilelist)
		echo "done rcp4.5 period means"

		# ---------- Computing difference ---------- #
		echo ""
		echo "Computing change = scenario - historical"
		for (( i=0; i<${#ofilelist_hist[@]}; i++ ))
		do
			ifile_hist=${ofilelist_hist[$i]}
			ifile_rcp26=${ofilelist_rcp26[$i]}
			ifile_rcp45=${ofilelist_rcp45[$i]}
			#ofile_rcp26_vs_hist=`echo $ifile_rcp26 | sed s/_periodmean/_periodmean_vs_hist${REFBEGIN}-${REFEND}_periodmean/`
			#ofile_rcp45_vs_hist=`echo $ifile_rcp45 | sed s/_periodmean/_periodmean_vs_hist${REFBEGIN}-${REFEND}_periodmean/`
			ofile_rcp26_vs_hist=`echo $ifile_rcp26 | sed s/.nc4/vs${REFBEGIN}-${REFEND}.nc4/`
			ofile_rcp45_vs_hist=`echo $ifile_rcp45 | sed s/.nc4/vs${REFBEGIN}-${REFEND}.nc4/`

			echo "Index $i"
			echo "	ifile_hist:        $(basename $ifile_hist)"
			echo "	ifile_rcp2.6:      $(basename $ifile_rcp26)"
			echo "	ofile_rcp2.6-hist: $(basename $ofile_rcp26_vs_hist)"
			echo "	ofile_rcp4.5-hist: $(basename $ofile_rcp45_vs_hist)"

			# Compute difference or percentage change (between future and reference) depending on index:
    		indexname=$(cdo showname $ifile_hist) #extract variable name from ncfile (only allow one variable per file)
    		indexname=${indexname[@]} #removes problem with space that may appear
			indices_that_need_percentage_change="prsum sdii pr997 prmax5day" #-# add indices that need percentage change here (and not difference) #-#
			[[ $indices_that_need_percentage_change =~ (^|[[:space:]])$indexname($|[[:space:]]) ]] && need_change=true || need_change=false #check if current index needs percentage change

			if $need_change; then 
				cdo -L -mulc,100 -div -sub $ifile_rcp26 $ifile_hist $ifile_hist $ofile_rcp26_vs_hist #percentage change: double check if correct
				cdo -L -mulc,100 -div -sub $ifile_rcp45 $ifile_hist $ifile_hist $ofile_rcp45_vs_hist #percentage change: double check if correct
				
				ncatted -O -a units,$indexname,o,c,"%" $ofile_rcp26_vs_hist #change units to percent
				ncatted -O -a units,$indexname,o,c,"%" $ofile_rcp45_vs_hist #change units to percent

				ncrename -v $indexname,change-$indexname $ofile_rcp26_vs_hist #change varname from 'var' to 'change-var'
				ncrename -v $indexname,change-$indexname $ofile_rcp45_vs_hist #change varname from 'var' to 'change-var'

			else
				cdo sub $ifile_rcp26 $ifile_hist $ofile_rcp26_vs_hist #simple difference
				cdo sub $ifile_rcp45 $ifile_hist $ofile_rcp45_vs_hist #simple difference

				ncrename -v $indexname,diff-$indexname $ofile_rcp26_vs_hist #change varname from 'var' to 'diff-var'
				ncrename -v $indexname,diff-$indexname $ofile_rcp45_vs_hist #change varname from 'var' to 'diff-var'

			fi

			add_attributes_to_file $ofile_rcp26_vs_hist #add attributes belonging to the variable change-var or diff-var 
			add_attributes_to_file $ofile_rcp45_vs_hist #add attributes belonging to the variable change-var or diff-var

		done
	exit
	done
	# ------------------------------------------ #
done


# # Continue here. The rest of the script is a proof-of-concept, outlining the order of commands, but they do not run.
# # Before they can run, there many special cases to treat: variable names/metadata, year selection, the fact that models cover different years etc.  



# # Change the name of the file and the variable name as shown in ncview:
# # See filename convensions in the modelling protocol, chapter 7.6. https://docs.google.com/document/d/1V9RBqdqUrMOYqfMVwcSHRwWP57fiS3R8/edit
# # Note here that bias-baseline could be either "eqm-sn2018v2005" or "3dbc-eqm-sn2018v2005", depending on the bias-adjustment method.
# ## ncrename -v tas,tas_annual-mean  $WORKDIR/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$REFBEGIN'-'$REFEND'.nc' $WORKDIR/$RCM/$VAR/$RCM_$RCP_eqm-sn2018v2005_none_norway_1km_tas_annual-mean_'$REFBEGIN'-'$REFEND'.nc'

# #ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1961-1990.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1961-1990.nc4'
# #ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1991-2000.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1991-2020.nc4'




# #  for pctls in 10 25 50 75 90; do
# #     cdo enspctl,$pctls  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc'
	
# #     cdo fldmean $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'
	
# #     echo 
# #     echo 'Printing fieldmean for 1991-2020, enspctl=' $enspctl
# #     echo 
	
# #     cdo info $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'

# # done   # Done looping over percentiles: 10,25,50,75,90



# echo "Add this when you have double-checked rm tmp/$USER/mergetime*"

# #return to starting dir
# cd $CURRDIR
# echo -ne "\n=====\nDone!\n"
# #---------------------------------------------------#

# #Notes from ibni:


# # $file = cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_1960.nc4
# # ofile=`basename $file | sed s/daily/monthly/`        # <- The original script computed monthly files from daily
# # files by using this line of code in the if sentence below:
# # Monthly mean of $VAR (no space to save this for all variables and models)	 
# # cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_$VAR_monmean 	 

# # vekstsesongens lengde
# 	# Denne er tricky fordi den skal beregnes fra en glattet kurve.
# 	# Fra dynamisk dokument: "Midlere vekstsesong i 30-års perioder gjøres utfra glattet kurve for temperaturutvikling gjennom året." 
# 	# den også tar inn filbane til landmaske. Og den skjønner ikke at jeg prøver å gi den to inputargumenter.
# 	# cdo eca_gsl $file $LANDMASK -gec,20 $file $RCM/$VAR/$ofile_gsl

# 	# vinter- og sommersesong inn her?

# 	# Avkjølingsgraddager, cooling days
# 	# Antall dager med TAM>=22 (gec) over året

# 	#cdo -s monsum -setrtoc,-Inf,0,0 -subc,295.15 $filedir/$file ./$RCM/$VAR/$ofile_cdd

# 	#ncatted -O -a short_name,tas,o,c,"cdd" 		          ./$RCM/$VAR/$ofile_cdd
# 	#ncatted -O -a units,tas,o,c,"degreedays" 			  ./$RCM/$VAR/$ofile_cdd
# 	#ncatted -O -a long_name,tas,o,c,"cooling_degree-days"           ./$RCM/$VAR/$ofile_cdd
	 

# # vekstsesongens lengde, Mean annual growing season (days>=5C). Merk at senorge er i degC, derfor terskel på 5, ikke 278.15.
# 	# mkdir -p "./senorge/growing/"                                                           # Testing senorge
# 	# echo "Ofile_growing=" ."/senorge/growing/"$ofile_growing
# 	# cdo timsum -gec,5 $filedir/$ofile ."/senorge/growing/"$ofile_growing  # med senorge-data må file være ofile!
# 	# trenger ikke månedsverdier:
# 	# cdo monsum -gec,5 $filedir/$ofile ."/senorge/growing/"$ofile_growing  # gir store månedsverdifiler.

# 	#ncatted -O -a standard_name,tg,o,c,"spell_length_of_days_with_air_temperature_above_threshold" ."/senorge/growing/"$ofile_growing
# 	#ncatted -O -a units,tg,o,c,"day" 		  		                                ."/senorge/growing/"$ofile_growing 
# 	#ncatted -O -a long_name,tg,o,c,"Mean annual growing season length (days TAS >=5 °C)"           ."/senorge/growing/"$ofile_growing
# 	##ncatted -O -a short_name,tg,o,c,"growing"                                                   ."/senorge/growing/"$ofile_growing
# 	## ncrename -v tg,growing .'/senorge/growing/'$ofile_growing .'/senorge/growing/'$ofile_growing                                                                                                                                                                                                                                                         t
# 			ncatted -O -a tracking_id,global,o,c,`uuidgen` $ofile_rcp45_vs_hist

# 		done
# 	exit
# 	done
# 	# ------------------------------------------ #
# done


# # Continue here. The rest of the script is a proof-of-concept, outlining the order of commands, but they do not run.
# # Before they can run, there many special cases to treat: variable names/metadata, year selection, the fact that models cover different years etc.  



# # Change the name of the file and the variable name as shown in ncview:
# # See filename convensions in the modelling protocol, chapter 7.6. https://docs.google.com/document/d/1V9RBqdqUrMOYqfMVwcSHRwWP57fiS3R8/edit
# # Note here that bias-baseline could be either "eqm-sn2018v2005" or "3dbc-eqm-sn2018v2005", depending on the bias-adjustment method.
# ## ncrename -v tas,tas_annual-mean  $WORKDIR/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$REFBEGIN'-'$REFEND'.nc' $WORKDIR/$RCM/$VAR/$RCM_$RCP_eqm-sn2018v2005_none_norway_1km_tas_annual-mean_'$REFBEGIN'-'$REFEND'.nc'

# #ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1961-1990.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1961-1990.nc4'
# #ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1991-2000.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1991-2020.nc4'




# #  for pctls in 10 25 50 75 90; do
# #     cdo enspctl,$pctls  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc'
	
# #     cdo fldmean $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'
	
# #     echo 
# #     echo 'Printing fieldmean for 1991-2020, enspctl=' $enspctl
# #     echo 
	
# #     cdo info $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'

# # done   # Done looping over percentiles: 10,25,50,75,90



# echo "Add this when you have double-checked rm tmp/$USER/mergetime*"

# #return to starting dir
# cd $CURRDIR
# echo -ne "\n=====\nDone!\n"
# #---------------------------------------------------#

# #Notes from ibni:


# # $file = cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_1960.nc4
# # ofile=`basename $file | sed s/daily/monthly/`        # <- The original script computed monthly files from daily
# # files by using this line of code in the if sentence below:
# # Monthly mean of $VAR (no space to save this for all variables and models)	 
# # cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_$VAR_monmean 	 

# # vekstsesongens lengde
# 	# Denne er tricky fordi den skal beregnes fra en glattet kurve.
# 	# Fra dynamisk dokument: "Midlere vekstsesong i 30-års perioder gjøres utfra glattet kurve for temperaturutvikling gjennom året." 
# 	# den også tar inn filbane til landmaske. Og den skjønner ikke at jeg prøver å gi den to inputargumenter.
# 	# cdo eca_gsl $file $LANDMASK -gec,20 $file $RCM/$VAR/$ofile_gsl

# 	# vinter- og sommersesong inn her?

# 	# Avkjølingsgraddager, cooling days
# 	# Antall dager med TAM>=22 (gec) over året

# 	#cdo -s monsum -setrtoc,-Inf,0,0 -subc,295.15 $filedir/$file ./$RCM/$VAR/$ofile_cdd

# 	#ncatted -O -a short_name,tas,o,c,"cdd" 		          ./$RCM/$VAR/$ofile_cdd
# 	#ncatted -O -a units,tas,o,c,"degreedays" 			  ./$RCM/$VAR/$ofile_cdd
# 	#ncatted -O -a long_name,tas,o,c,"cooling_degree-days"           ./$RCM/$VAR/$ofile_cdd
	 

# # vekstsesongens lengde, Mean annual growing season (days>=5C). Merk at senorge er i degC, derfor terskel på 5, ikke 278.15.
# 	# mkdir -p "./senorge/growing/"                                                           # Testing senorge
# 	# echo "Ofile_growing=" ."/senorge/growing/"$ofile_growing
# 	# cdo timsum -gec,5 $filedir/$ofile ."/senorge/growing/"$ofile_growing  # med senorge-data må file være ofile!
# 	# trenger ikke månedsverdier:
# 	# cdo monsum -gec,5 $filedir/$ofile ."/senorge/growing/"$ofile_growing  # gir store månedsverdifiler.

# 	#ncatted -O -a standard_name,tg,o,c,"spell_length_of_days_with_air_temperature_above_threshold" ."/senorge/growing/"$ofile_growing
# 	#ncatted -O -a units,tg,o,c,"day" 		  		                                ."/senorge/growing/"$ofile_growing 
# 	#ncatted -O -a long_name,tg,o,c,"Mean annual growing season length (days TAS >=5 °C)"           ."/senorge/growing/"$ofile_growing
# 	##ncatted -O -a short_name,tg,o,c,"growing"                                                   ."/senorge/growing/"$ofile_growing
	## ncrename -v tg,growing .'/senorge/growing/'$ofile_growing .'/senorge/growing/'$ofile_growing

# Irene is testing senorge:
		###ofile=`basename $file | sed s/senorge2018_//`          # Testing senorge. Format: tg_senorge2018_2008.nc



        #if [ "$VAR" == "tas" ] || [ "$VAR" == "tg" ]; then    # Testing seNorge

			#ofile_tas_annual=`echo $ofile | sed s/_tg_/_tg_annual-mean_/`      # Testing senorge
			#ofile_tas_seasonal=`echo $ofile | sed s/_tg_/_tg_seasonal-mean_/`  # Testing senorge 
			#ofile_growing=`echo $ofile | sed s/_tg_/_growing_/`                # Testing senorge: vekstsesong
			
			#set tasmin to tasmax because they are treated in the same way
			#VAR="tasmax"      # set the first variable is tasmax and treat tasmin equally.  # orig. Roll back to this.
			#VAR="tx"          # Testing senorge

			#ofile_tas_annual=`echo $ofile | sed s/_tg_/_tg_annual_/`      # Testing senorge
			#ofile_tas_seasonal=`echo $ofile | sed s/_tg_/_tg_seasonal_/`  # Testing senorge 
			#ofile_growing=`echo $ofile | sed s/_tg_/_growing_/`           # Testing senorge: vekstsesong