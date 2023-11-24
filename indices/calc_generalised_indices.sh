#!/bin/bash

##!/usr/bin/bash   # <- use this on Lustre
set -e #exit on error


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
		###ofile=`basename $file | sed s/senorge2018_//`          # Testing senorge. Format: tg_senorge2018_2008.nc




        #if [ "$VAR" == "tas" ] || [ "$VAR" == "tg" ]; then    # Testing seNorge
		if [ $VAR == "tas" ]; then
			echo ""
			echo "tas chosen. Now processing ifile " $file ", which is number " $(( $count+1 )) " out of " $nbrfiles " (from one model, RCM and RCP only)."
			
			## For each index: Make ofilenames by substituting _varname_ (here: _tas_) with _indexname_ (potentially with time resolution)
			local ofile_tas_annual=`echo $ofile | sed s/_tas_/_tas_annual-mean_/`     # orig. Roll back to this.
			local ofile_tas_seasonal=`echo $ofile | sed s/_tas_/_tas_seasonal-mean_/` # orig. Roll back to this.
			local ofile_cdd=`echo $ofile | sed s/_tas_/_cdd_/`                        # orig. Roll back to this.
			local ofile_gsl=`echo $ofile | sed s/_tas_/_gsl_/`                        # orig. Roll back to this. 
			#-# NEW INDEX from tas? Add line (as above) here #-#

			#ofile_tas_annual=`echo $ofile | sed s/_tg_/_tg_annual-mean_/`      # Testing senorge
			#ofile_tas_seasonal=`echo $ofile | sed s/_tg_/_tg_seasonal-mean_/`  # Testing senorge 
			#ofile_growing=`echo $ofile | sed s/_tg_/_growing_/`                # Testing senorge: vekstsesong

			## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_tas_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_tas_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				#-# NEW INDEX from tas? Add two lines (as above) here #-#
			fi


			# Compute tas_annual
			if ! [ -f ./$RCM/$VAR/$ofile_tas_annual ]; then   # check that the file does not exist
				cdo timmean   -ifthen $LANDMASK $filedir/$file  ./$RCM/$VAR/$ofile_tas_annual
				#ncatted -O -a long_name,tas,o,c,"annual average_of_air_temperature" ./$RCM/$VAR/$ofile_tas_annual
				#ncrename -v tas,tas ./$RCM/$VAR/$ofile_tas_annual #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation of tas_annual from daily data, because ofile already exists for year " $yyyy
			fi
	    
			# Compute tas_seasonal
 			if ! [ -f ./$RCM/$VAR/$ofile_tas_seasonal ]; then
				cdo -L yseasmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_tas_seasonal
				#ncatted -O -a long_name,tas,o,c,"seasonal average_of_air_temperature" ./$RCM/$VAR/$ofile_tas_seasonal
				## ncrename -v tas,tas ./$RCM/$VAR/$ofile_tas_seasonal ./$RCM/$VAR/$ofile_tas_seasonal	 
			else
				echo "Skip computation of tas_seasonal from daily data, because ofile already exists for year " $yyyy
			fi 
			#-# NEW INDEX from tas? Add the if-block with cdo-command and ncrename (as above) here #-#
			#-# crop domain to mainland Norway before processing by "-ifthen $LANDMASK" (as above) #-#
	 


		# elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ] || [ $VAR == "tx" ] || [ $VAR == "tn" ]; then   # Testing senorge
		elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ]; then             # orig. Roll back to this.

			#set tasmin to tasmax because they are treated in the same way
			VAR="tasmax"      # set the first variable is tasmax and treat tasmin equally.  # orig. Roll back to this.
			#VAR="tx"          # Testing senorge

				echo ""
			echo "tasmax chosen (and tasmin automatically read in). Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."

			# Gjennomsnitt av tasmax
			mkdir -p  $RCM/tasmax/
			local ofile_tasmax_annual=`echo $ofile | sed s/_tasmax_/_tasmax_annual-mean_/`
			local ofile_tasmax_seasonal=`echo $ofile | sed s/_tasmax_/_tasmax_seasonal-mean_/`	 
			#ofile_tasmax_monmean=`echo $ofile | sed s/_tasmax_/_tasmax_monmean_/`
			#ofile_tasmin_monmean=`echo $ofile | sed s/_tasmax_/_tasmin_monmean_/`

			#ofile_dtr=`echo $ofile | sed s/_tasmax_/_dtr_/`
			#ofile_dzc=`echo $ofile | sed s/_tasmax_/_dzc_/`
			local ofile_fd=`echo $ofile | sed s/_tasmax_/_fd_/`
			local ofile_tropnight=`echo $ofile | sed s/_tasmax_/_tropnight_/`
			local ofile_norheatwave=`echo $ofile | sed s/_tasmax_/_norheatwave_/`
			local ofile_summerdnor=`echo $ofile | sed s/_tasmax_/_summerdnor_/`
			local ofile_summerd=`echo $ofile | sed s/_tasmax_/_summerd_/`


			# cdo ifthen $LANDMASK -monmean ./$RCM/'/mergetime_norheatwave_'$REFBEGIN'-'$REFEND'.nc'     ./$RCM'/land_tasmax'
			# cdo ifthen $LANDMASK -monmean ./$RCM/'/mergetime_norheatwave_'$REFBEGIN'-'$REFEND'.nc'     ./$RCM'/land_norheatwave'
				
	 
			# Annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_tasmax_annual ]; then   # check if the file exists
				cdo timmean                -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_tasmax_annual
				# flytt metadata hit når de er klare?
			fi
	 
			if ! [ -f ./$RCM/$VAR/$ofile_tasmax_seasonal ]; then   # check if the file exists

				cdo timmean -selmon,12,1,2 -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"DJFmean.nc"
				cdo timmean -selmon,3/5    -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"MAMmean.nc"
				cdo timmean -selmon,6/8    -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"JJAmean.nc"
				cdo timmean -selmon,9/11   -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"SONmean.nc"

				cdo cat ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" ./$RCM/$VAR/$ofile_tas_seasonal
				rm ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc"
				# flytt metadata hit når de er klare?
			fi
	 
			# Monthly mean of $VAR (no space to save this for all variables and models)	 
			# cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/tasmax/$ofile_tasmax_monmean

			# Read in tasmin
			local ifileN=`echo $file | sed s/_tasmax_/_tasmin_/`
			local ifiledirN=`echo $filedir | sed s/_tasmax_/_tasmin_/`
			echo $ifiledirN/$ifileN

			# Gjennomsnitt av tasmin
			mkdir -p  $RCM/tasmin/
			local ofile_tasmin_annual=`echo $ofile | sed s/_tasmax_/_tasmin_annual-mean_/`
			local ofile_tasmin_seasonal=`echo $ofile | sed s/_tasmax_/_tasmin_seasonal-mean_/`	 

			# Annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_tasmin_annual ]; then   # check if the file exists
				cdo timmean                -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_tasmin_annual
				# flytt metadata hit når de er klare?
			fi
	 
			if ! [ -f ./$RCM/$VAR/$ofile_tasmin_seasonal ]; then   # check if the file exists
	     
				#cdo timmean                -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_tas_annual

				cdo timmean -selmon,12,1,2 -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"DJFmean.nc"
				cdo timmean -selmon,3/5    -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"MAMmean.nc"
				cdo timmean -selmon,6/8    -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"JJAmean.nc"
				cdo timmean -selmon,9/11   -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/"SONmean.nc"
				cdo cat ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" ./$RCM/$VAR/$ofile_tas_seasonal
				rm ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc"

				# Monthly mean of $VAR (no space to save this for all variables and models)
				# cdo -s monmean -ifthen $LANDMASK $ifiledirN/$ifileN ./$RCM/tasmin/$ofile_tasmin_monmean
				echo "Tasmin: done"
				# flytt metadata hit når de er klare?
			fi
	 

			# DTR
			if ! [ -f ./$RCM/$VAR/$ofile_dtr ]; then   # check if the file exists

				#ofile_dtr=`echo $ofile | sed s/_tasmax_/_dtr_/`  # <- this is written higher up
				mkdir -p  $RCM/dtr/
				local ofile_dtr_annual=`echo $ofile | sed s/_tasmax_/_dtr_annual-mean_/`	 
				local ofile_dtr_seasonal=`echo $ofile | sed s/_tasmax_/_dtr_seasonal-mean_/`
				#ofile_dtr=`echo $ofile | sed s/_tasmax_/_dtr_/`

				echo "Ofile_dtr=" $RCM"/dtr/"$ofile_dtr	 
				cdo sub -ifthen $LANDMASK $filedir/$file $ifiledirN/$ifileN ./$RCM/dtr/$ofile_dtr
			fi

	 	 
			# DZC, nullgradspasseringer
			if ! [ -f ./$RCM/$VAR/$ofile_dzc ]; then   # check if the file exists
				mkdir -p  $RCM/dzc/
				local ofile_dzc_annual=`echo $ofile | sed s/_tasmax_/_dzc_annual-mean_/`
				local ofile_dzc_seasonal=`echo $ofile | sed s/_tasmax_/_dzc_seasonal-mean_/`	 
				echo "Ofile_dzc=" $RCM"/dzc/"$ofile_dzc	 
				cdo monsum -mul -ltc,273.15 -ifthen $LANDMASK $ifiledirN/$ifileN -gtc,273.15 -ifthen $LANDMASK $filedir/$file ./$RCM/dzc/$ofile_dzc
			fi


			# Frostdager, fd # under 0 grader
			if ! [ -f ./$RCM/$VAR/$ofile_fd ]; then   # check if the file exists
				mkdir -p $RCM/fd/
				echo "Ofile_fd=" $RCM"/fd/"$ofile_fd
				cdo monsum -ltc,273.15 -ifthen $LANDMASK $ifiledirN/$ifileN ./$RCM/fd/$ofile_fd
			fi
	 
	 
			# tropenattdøgn # Tmin >= 20 grader
			if ! [ -f ./$RCM/$VAR/$ofile_tropnight ]; then   # check if the file exists
				mkdir -p $RCM/tropnight/
				echo "Ofile_tropnight=" $RCM"/tropnight/"$ofile_tropnight
				cdo -s monsum -gec,293.15 -ifthen $LANDMASK $ifiledirN/$ifileN ./$RCM/tropnight/$ofile_tropnight
			fi
	 
			# Nordiske sommerdager # over 20 grader
			if ! [ -f ./$RCM/$VAR/$ofile_norsummer ]; then   # check if the file exists
				mkdir -p  $RCM/norsummer/
				echo "Ofile_norsummer=" $RCM"/norsummer/"$ofile_norsummer	 	 
				cdo monsum -gec,293.15 -ifthen $LANDMASK $filedir/$file ./$RCM/norsummer/$ofile_norsummer
			fi

			# Nordiske sommerdager # over 25 grader
			if ! [ -f ./$RCM/$VAR/$ofile_summerdays ]; then   # check if the file exists
				mkdir -p  $RCM/summerdays/	 
				echo "Ofile_summerdays=" $RCM"/summerdays/"$ofile_summerdays 	 
				cdo monsum -gec,298.15 -ifthen $LANDMASK $filedir/$file ./$RCM/summerdays/$ofile_summerdays
			fi
	 
			# norsk hetebølge # over 27 grader
			#ofile_norheatwave=`echo $ofile | sed s/_tasmax_/_norheatwave_/`
			if ! [ -f ./$RCM/$VAR/$ofile_norheatwave ]; then   # check if the file exists
				mkdir -p $RCM/norheatwave/
				cdo monsum -gec,300.15 -runmean,5 -ifthen $LANDMASK $filedir/$file ./$RCM/norheatwave/$ofile_norheatwave 
				echo "norsk hetebølge: done"
			fi    


			# Til alle standard_name under: Kan vurdere å legge inn variabel threshold (float threshold;   threshold:standard_name="air_temperature";    threshold:units="degC"; data: threshold=0.;)	 
			ncatted -O -a standard_name,global,o,c,"number_of_days_with_air_temperature_below_threshold"    ./$RCM/dzc/$ofile_dzc
			# ncatted -O -a metno_name,global,o,c,"number_of_days_with_air_temperature_crossing_threshold"    ./$RCM/dzc/$ofile_dzc  <- not standard_name 
			ncatted -O -a standard_name,global,o,c,"number_of_days_with_air_temperature_below_threshold"    ./$RCM/fd/$ofile_fd
			ncatted -O -a standard_name,global,o,c,"number_of_days_with_air_temperature_above_threshold"    ./$RCM/tropnight/$ofile_tropnight 	
			ncatted -O -a standard_name,global,o,c,"number_of_days_with_air_temperature_above_threshold"    ./$RCM/norsummer/$ofile_norsummer
			ncatted -O -a standard_name,global,o,c,"number_of_days_with_air_temperature_above_threshold"    ./$RCM/summerdays/$ofile_summerdays
			ncatted -O -a metno_name,global,o,c,"number_of_events_with_air_temperature_above_threshold"     ./$RCM/norheatwave/$ofile_norheatwave
			# NB: norheatwave arver nå standard_name fra hovedfila, dvs "air_temperature". Kan vurdere å fjerne standard_name.

			# Forslag:
			ncatted -O -a cell_methods,global,o,c,"time: minimum within days and maximum within days time: sum over days"    ./$RCM/fd/$ofile_dzc
			ncatted -O -a cell_methods,global,o,c,"time: minimum within days time: sum over days"    ./$RCM/fd/$ofile_fd
			ncatted -O -a cell_methods,global,o,c,"time: maximum within days time: sum over days"    ./$RCM/fd/$ofile_tropnight
			ncatted -O -a cell_methods,global,o,c,"time: maximum within days time: sum over days"    ./$RCM/fd/$ofile_norsummer
			ncatted -O -a cell_methods,global,o,c,"time: maximum within days time: sum over days"    ./$RCM/fd/$ofile_summerdays
			ncatted -O -a cell_methods,global,o,c,"time: maximum within days time: number of events"    ./$RCM/fd/$ofile_norheatwave # <- må sjekkes

			ncatted -O -a short_name,tasmax,o,c,"tasmax"      ./$RCM/tasmax/$ofile_tasmax
			ncatted -O -a short_name,tasmin,o,c,"tasmin"      ./$RCM/tasmin/$ofile_tasmin
			ncatted -O -a short_name,tasmax,o,c,"dtr" 	   ./$RCM/dtr/$ofile_dtr
			ncatted -O -a short_name,tasmin,o,c,"dzc" 	   ./$RCM/dzc/$ofile_dzc 	
			ncatted -O -a short_name,tasmin,o,c,"fd" 	   ./$RCM/fd/$ofile_fd
			ncatted -O -a short_name,tasmin,o,c,"tropnight"   ./$RCM/tropnight/$ofile_tropnight 	
			ncatted -O -a short_name,tasmax,o,c,"norsummer"   ./$RCM/norsummer/$ofile_norsummer
			ncatted -O -a short_name,tasmax,o,c,"summerdays"  ./$RCM/summerdays/$ofile_summerdays
			ncatted -O -a short_name,tasmax,o,c,"norheatwave" ./$RCM/norheatwave/$ofile_norheatwave 

			ncatted -O -a units,tasmax,o,c,"K" 		   ./$RCM/tasmax/$ofile_tasmax
			ncatted -O -a units,tasmin,o,c,"K" 		   ./$RCM/tasmin/$ofile_tasmin
			ncatted -O -a units,tasmax,o,c,"K" 		   ./$RCM/dtr/$ofile_dtr 
			ncatted -O -a units,tasmin,o,c,"days" 		   ./$RCM/dzc/$ofile_dzc
			ncatted -O -a units,tasmin,o,c,"days" 		   ./$RCM/fd/$ofile_fd
			ncatted -O -a units,tasmin,o,c,"days" 		   ./$RCM/tropnight/$ofile_tropnight
			ncatted -O -a units,tasmax,o,c,"days" 		   ./$RCM/norsummer/$ofile_norsummer
			ncatted -O -a units,tasmax,o,c,"days" 	 	   ./$RCM/summerdays/$ofile_summerdays	
			ncatted -O -a units,tasmax,o,c,"number of events" ./$RCM/norheatwave/$ofile_norheatwave

			# Mulig bug: dette er standard name, ikke long_name. Vurdere å endre teksten til det lange navnet? 
			ncatted -O -a long_name,tasmax,o,c,"average_of_maximum_air_temperature"     ./$RCM/tasmax/$ofile_tasmax
			ncatted -O -a long_name,tasmin,o,c,"average_of_minimum_air_temperature"     ./$RCM/tasmin/$ofile_tasmin
			ncatted -O -a long_name,tasmax,o,c,"diurnal temperature range"  	     ./$RCM/dtr/$ofile_dtr
			ncatted -O -a long_name,tasmin,o,c,"number_of_days_with_zero_crossings"     ./$RCM/dzc/$ofile_dzc
			ncatted -O -a long_name,tasmin,o,c,"number_of_frost_days_tasmin-below-0"    ./$RCM/fd/$ofile_fd
			ncatted -O -a long_name,tasmin,o,c,"number of tropical nights" 	     ./$RCM/tropnight/$ofile_tropnight
			ncatted -O -a long_name,tasmax,o,c,"nordic_summer_days_tasmax-exceeding-20" ./$RCM/norsummer/$ofile_summerdnor
			ncatted -O -a long_name,tasmax,o,c,"summer_days_tasmax-exceeding-20"        ./$RCM/summerdays/$ofile_summerdays 
			ncatted -O -a long_name,tasmax,o,c,"norwegian_heatwave_index"               ./$RCM/norheatwave/$ofile_norheatwave	

			ofileList="${ofile_tasmax_annual} ${ofile_tasmax_seasonal} ${ofile_tasmin_annual} ${ofile_tasmin_seasonal}"


		elif [ $VAR == "pr" ]; then
			echo ""
			echo "pr chosen. Now processing ifile " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."

			## For each index: Make ofilenames by substituting _varname_ (here: _pr_) with _indexname_ (potentially with time resolution)
			local ofile_prsum_annual=`echo $ofile | sed s/_pr_/_prsum_annual_/` # sum of pr over year
			local ofile_prsum_seasonal=`echo $ofile | sed s/_pr_/_prsum_seasonal_/` #sum of pr over seasons 
			#-# NEW INDEX from pr? Add line (as above) here #-#

			## For first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_prsum_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_prsum_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"

				#-# NEW INDEX from pr? Add two lines (as above) here #-#
			fi

			# Compute prsum_annual
			if ! [ -f ./$RCM/$VAR/$ofile_prsum_annual ]; then   # check if the file exists
				cdo timsum -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_prsum_annual
				ncrename -v pr,prsum ./$RCM/$VAR/$ofile_prsum_annual #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation from daily data, because ofile already exists for" "prsum_annual" $yyyy
			fi

			# Compute prsum_seasonal
			if ! [ -f ./$RCM/$VAR/$ofile_prsum_seasonal ]; then   # check if the file exists
				cdo -L yseassum -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_prsum_seasonal
				ncrename -v pr,prsum ./$RCM/$VAR/$ofile_prsum_seasonal #https://linux.die.net/man/1/ncrename
			else
				echo "Skip computation from daily data, because ofile already exists for" "prsum_seasonal" $yyyy
			fi
	 
			#-# NEW INDEX from pr? Add the if-block with cdo-command and ncrename (as above) here #-#
			#-# crop domain to mainland Norway before processing by "-ifthen $LANDMASK" (as above) #-#


		# elif [ $VAR == "hurs" ]; then
			# 	 echo ""
			#    echo "hurs chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_hurs_monmean=`echo $ofile | sed s/_hurs_/_hurs_monmean_/`	 

			# 	 # Monthly mean av hurs
			#    cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_hurs_monmean	 

			# 	 ncatted -O -a short_name,hurs,o,c,"hurs_monmean" 		                ./$RCM/$VAR/$ofile_hurs_monmean	 
			# 	 ncatted -O -a units,hurs,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_hurs_monmean
			# 	 ncatted -O -a long_name,hurs,o,c,"surface_downwelling_shortwave_flux_in_air"	./$RCM/$VAR/$ofile_hurs_monmean


		# elif [ $VAR == "rlds" ]; then
			# 	 echo ""
			#    echo "rlds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rlds_monmean=`echo $ofile | sed s/_rlds_/_rlds_monmean_/`	 
			
			# 	 # Monthly mean av rlds
			#    cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_rlds_monmean	 
			
			# 	 ncatted -O -a short_name,rlds,o,c,"rlds_monmean"                  	        ./$RCM/$VAR/$ofile_rlds_monmean	 
			# 	 ncatted -O -a units,rlds,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_rlds_monmean
			# 	 ncatted -O -a long_name,rlds,o,c,"surface_downwelling_longwave_flux_in_air"	./$RCM/$VAR/$ofile_rlds_monmean


		#  elif [ $VAR == "rsds" ]; then
			# 	 echo ""
			#    echo "rsds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rsds_monmean=`echo $ofile | sed s/_rsds_/_rsds_monmean_/`	 
			
			# 	 # Monthly mean av rsds
			#    cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_rsds_monmean	 
			
			# 	 ncatted -O -a short_name,rsds,o,c,"rsds_monmean"         ./$RCM/$VAR/$ofile_rsds_monmean	 
			# 	 ncatted -O -a units,rsds,o,c,"%"                         ./$RCM/$VAR/$ofile_rsds_monmean
			# 	 ncatted -O -a long_name,rsds,o,c,"relative humidity"     ./$RCM/$VAR/$ofile_rsds_monmean

			
		#  elif [ $VAR == "ps" ]; then
			# 	 echo ""
			#    echo "ps chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_ps_monmean=`echo $ofile | sed s/_ps_/_ps_monmean_/`	 
			
			# 	 # Monthly mean av ps
			#    cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_ps_monmean	 
			
			# 	 ncatted -O -a short_name,ps,o,c,"ps_monmean" 		./$RCM/$VAR/$ofile_ps_monmean	 
			# 	 ncatted -O -a units,ps,o,c,"Pa" 		        ./$RCM/$VAR/$ofile_ps_monmean
			# 	 ncatted -O -a long_name,ps,o,c,"surface_air_pressure"	./$RCM/$VAR/$ofile_ps_monmean



		#  elif [ $VAR == "sfcWind" ]; then
			# 	 echo ""
			#    echo "sfcWind chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_sfcWind_monmean=`echo $ofile | sed s/_sfcWind_/_sfcWind_monmean_/`	 
			
			# 	 # Monthly mean av sfcWind
			#    cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_sfcWind_monmean	 
			
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
			cdo yseasmean $ofilepath1 $ofilepath2 #yseasmean (instead of timmean) makes the mean calculation work for both annual and seasonal data.
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
echo "Accepted all (default and user) inputs of rcms, periods and variables. Proceed"

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

			cdo sub $ifile_rcp26 $ifile_hist $ofile_rcp26_vs_hist
			cdo sub $ifile_rcp45 $ifile_hist $ofile_rcp45_vs_hist

			ncatted -O -a tracking_id,global,o,c,`uuidgen` $ofile_rcp26_vs_hist
			ncatted -O -a tracking_id,global,o,c,`uuidgen` $ofile_rcp45_vs_hist

		done
	exit
	done
	# ------------------------------------------ #
done


# Continue here. The rest of the script is a proof-of-concept, outlining the order of commands, but they do not run.
# Before they can run, there many special cases to treat: variable names/metadata, year selection, the fact that models cover different years etc.  



# Change the name of the file and the variable name as shown in ncview:
# See filename convensions in the modelling protocol, chapter 7.6. https://docs.google.com/document/d/1V9RBqdqUrMOYqfMVwcSHRwWP57fiS3R8/edit
# Note here that bias-baseline could be either "eqm-sn2018v2005" or "3dbc-eqm-sn2018v2005", depending on the bias-adjustment method.
## ncrename -v tas,tas_annual-mean  $WORKDIR/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$REFBEGIN'-'$REFEND'.nc' $WORKDIR/$RCM/$VAR/$RCM_$RCP_eqm-sn2018v2005_none_norway_1km_tas_annual-mean_'$REFBEGIN'-'$REFEND'.nc'

#ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1961-1990.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1961-1990.nc4'
#ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1991-2000.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1991-2020.nc4'




#  for pctls in 10 25 50 75 90; do
#     cdo enspctl,$pctls  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc'
	
#     cdo fldmean $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'
	
#     echo 
#     echo 'Printing fieldmean for 1991-2020, enspctl=' $enspctl
#     echo 
	
#     cdo info $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'

# done   # Done looping over percentiles: 10,25,50,75,90



echo "Add this when you have double-checked rm tmp/$USER/mergetime*"

#return to starting dir
cd $CURRDIR
echo -ne "\n=====\nDone!\n"
#---------------------------------------------------#

#Notes from ibni:


# $file = cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_1960.nc4
# ofile=`basename $file | sed s/daily/monthly/`        # <- The original script computed monthly files from daily
# files by using this line of code in the if sentence below:
# Monthly mean of $VAR (no space to save this for all variables and models)	 
# cdo -s monmean -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_$VAR_monmean 	 

# vekstsesongens lengde
	# Denne er tricky fordi den skal beregnes fra en glattet kurve.
	# Fra dynamisk dokument: "Midlere vekstsesong i 30-års perioder gjøres utfra glattet kurve for temperaturutvikling gjennom året." 
	# den også tar inn filbane til landmaske. Og den skjønner ikke at jeg prøver å gi den to inputargumenter.
	# cdo eca_gsl $file $LANDMASK -gec,20 $file $RCM/$VAR/$ofile_gsl

	# vinter- og sommersesong inn her?

	# Avkjølingsgraddager, cooling days
	# Antall dager med TAM>=22 (gec) over året

	#cdo -s monsum -setrtoc,-Inf,0,0 -subc,295.15 -ifthen $LANDMASK $filedir/$file ./$RCM/$VAR/$ofile_cdd

	#ncatted -O -a short_name,tas,o,c,"cdd" 		          ./$RCM/$VAR/$ofile_cdd
	#ncatted -O -a units,tas,o,c,"degreedays" 			  ./$RCM/$VAR/$ofile_cdd
	#ncatted -O -a long_name,tas,o,c,"cooling_degree-days"           ./$RCM/$VAR/$ofile_cdd
	 

# vekstsesongens lengde, Mean annual growing season (days>=5C). Merk at senorge er i degC, derfor terskel på 5, ikke 278.15.
	# mkdir -p "./senorge/growing/"                                                           # Testing senorge
	# echo "Ofile_growing=" ."/senorge/growing/"$ofile_growing
	# cdo timsum -gec,5 -ifthen $LANDMASK $filedir/$ofile ."/senorge/growing/"$ofile_growing  # med senorge-data må file være ofile!
	# trenger ikke månedsverdier:
	# cdo monsum -gec,5 -ifthen $LANDMASK $filedir/$ofile ."/senorge/growing/"$ofile_growing  # gir store månedsverdifiler.

	#ncatted -O -a standard_name,tg,o,c,"spell_length_of_days_with_air_temperature_above_threshold" ."/senorge/growing/"$ofile_growing
	#ncatted -O -a units,tg,o,c,"day" 		  		                                ."/senorge/growing/"$ofile_growing 
	#ncatted -O -a long_name,tg,o,c,"Mean annual growing season length (days TAS >=5 °C)"           ."/senorge/growing/"$ofile_growing
	##ncatted -O -a short_name,tg,o,c,"growing"                                                   ."/senorge/growing/"$ofile_growing
	## ncrename -v tg,growing .'/senorge/growing/'$ofile_growing .'/senorge/growing/'$ofile_growing