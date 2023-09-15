#!/bin/bash

##!/usr/bin/bash   # <- use this on Lustre
set -e #exit on error


## Script to calculate annual and seasonal values for various indices from the bias-adjusted RCM data
#
# EQM and 3DBC
# Hist, rcp26 and rcp45 so far, ssp3.70 to follow
#
# Call: ./calc_generalised_indices.sh --var VAR --refbegin 1991 --refend 2020 --scenbegin 2071 --scenend 2100 --rcm modelA modelB modelC etc.
#  where VAR is one of hurs, pr, ps, rlds, rsds, sfcWind, tas, tasmax; later also mrro (runoff), swe (snow), esvpbls (evapotranspiration), soilmoist (soil moisture deficit)
#  and reference and scenario begin and end years are set using the corresponding arguments.
#  A selection of RCMs can be made using --rcm followed by a list of RCMs separated by spaces (not working yet).
#  For additional status messages you may use --verbose.
# Output from tas is cdd (cooling days) and tas_monmean
# Output from tasmax is dtr, dzc, fd, norheatwave, norsummer, summerdays, tasmax, tasmin, tropnight.  
#
# Run from workdir=/hdata/hmdata/KiN2100/analyses/indicators/calc_gen_indices/ <- remember opening a screen terminal.
# NOT workdir=/lustre/storeC-ext/users/kin2100/NVE/analyses/calc_gen_indices # foreløpig: test_ibni
# NOT workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc
                   
# Default values (used if not specified by the input arguments mentioned above):
#rcmlist=all
rcmlist=("cnrm-r1i1p1-aladin" "ecearth-r12i1p1-cclm") # all
refbegin=1994
refend=1995 #2020
scenbegin=2073
scenend=2074 #2100
verbose=0
VAR=tas

args=( )

while (( $# )); do
	case $1 in
		--var)       VAR=$2 ;;
		--refbegin)  refbegin=$2 ;;
		--refend)    refend=$2 ;;
		--scenbegin) scenbegin=$2 ;;
		--scenend)   scenend=$2 ;;
		--rcm)  rcmlist=$(echo $2 | tr ',' '\n'); rcmlist=($rcmlist);; # change from comma to space as separator
		--verbose)   verbose=1 ;;
		-*) printf 'Unknown option: %q\n\n' "$1"
			exit 1 ;; # Aborts when called with unsupported arguments.
		*)  args+=( "$1" ) ;;
	esac
	shift
done

echo ${rcmlist[@]} # all
#echo ${rcmlist[0]}
#echo ${rcmlist[-1]}


if [ $verbose -eq 1 ]; then
	echo "rcmlist" $rcmlist
	echo "refbegin" $refbegin
	echo "refend" $refend
	echo "scenbegin" $scenbegin
	echo "scenend" $scenend
fi

# ProgressBar function (from https://github.com/fearside/ProgressBar/)
# to show the current progress while running
# Input is currentState($1) and totalState($2)
function ProgressBar {
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

# Scroll down below (all functions) to see the main script. 

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
    filestart=`echo $filestart | sed s/$2//`   # replace year with nothing in string

}


function calc_indices {       # call this function with one input argument: filedir 

    # on the form /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/
    # or          /hdata/hmdata/KiN2100/ForcingData/BiasAdjust/eqm/netcdf/cnrm-r1i1p1-aladin/tas/rcp26/ 
    # I tried adding two input arguments:  filedir and $landmask, but that did not work.
    local count=0
    local filedir=$1
    
    echo "Filedir = " $filedir
    local filelist=`ls $1`  # This is the original line. Roll back to it!
    # filelist=`ls $1/$VAR*`   # testing senorge ls senorgepath/tx*
    # lists files on the form $RCM_rcp26_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_2100.nc4
    #local nbrfiles=`echo $filelist | wc -w`
    let nbrfiles=$(( $refend-$refbegin+1 ))
    echo $nbrfiles
    #    $filedir_EQM/$RCM/$VAR/hist/
        
    echo "Processing " $1
    # echo "Processing " $nbrfiles " files"
    # echo "Landmask = " $landmask
    
    ######## A note on subsetting by years:
    ### I guess you can replace filelist by filelist_subset if you want specific years.
    ### The rationale behind this script is possibly that monthly files are generated one time only, then stored?
    ### In that case, subsetting is done later in the process.
    ### Note, too, that the different RCMs span different years.
    ### ls $1'/cnrm-r1i1p1-aladin_rcp26_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_'{2071..2100}'.nc4'
    ### echo ls $1'/'$RCM'_rcp26_eqm-sn2018v2005_rawbc_norway_1km_'$VAR'_daily_'{2071..2100}'.nc4'
    # filelist_subset=`ls $1'/'$RCM'_rcp26_eqm-sn2018v2005_rawbc_norway_1km_'$VAR'_daily_'{2071..2100}'.nc4'`
    # echo "Subsetted Filelist = " $filelist_subset
    # nbrfiles_subset=`echo $filelist_subset | wc -w`
    
    
    #   for file in $filelist                # replaced looping over filenames with looping over (chosen) years

    local scenario=`basename $1`   #extract characters  
    echo $scenario
    
    if [ $scenario == "hist" ]; then # | [ $period == "senorge" ]
		firstyear=$refbegin
		lastyear=$refend
    elif [ $scenario == "rcp26" ] || [ $scenario == "rcp45" ]; then
		firstyear=$scenbegin
		lastyear=$scenend
    else
		echo "check if you are computing the right thing."
    fi
	
	ofilestartlist=""
	
    for yyyy in $( seq $firstyear $lastyear )   # list chosen years. NOTE: this only takes in the reference period.
    #    for yyyy in $( seq $refbegin $refend ; seq $scenbegin $scenend )   # list chosen years.
    do
		file=`ls "$1"/*$yyyy.nc4`      # cannot be "local".
		local file=`basename $file`                   
		echo "file is: " $file
		local ofile=`echo $file | sed s/daily_//`                   # later, this text is replaced with the variable name etc.
		echo "Ofile is: " $ofile
		###ofile=`basename $file | sed s/senorge2018_//`          # Testing this for seNorge. Format: tg_senorge2018_2008.nc

		# $file = cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_1960.nc4
		# ofile=`basename $file | sed s/daily/monthly/`        # <- The original script computed monthly files from daily
		# files by using this line of code in the if sentence below:
		# Monthly mean of $VAR (no space to save this for all variables and models)	 
		# cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_$VAR_monmean



        #if [ "$VAR" == "tas" ] || [ "$VAR" == "tg" ]; then    # Testing seNorge
		if [ $VAR == "tas" ]; then                             # orig. Roll back to this.
			echo ""
			echo "tas chosen. Now processing file " $file ", which is number " $(( $count+1 )) " out of " $nbrfiles " (from one model, RCM and RCP only)."
			local ofile_tas_annual=`echo $ofile | sed s/tas/tas_annual-mean/`     # orig. Roll back to this.
			local ofile_tas_seasonal=`echo $ofile | sed s/tas/tas_seasonal-mean/` # orig. Roll back to this.

			local ofile_cdd=`echo $ofile | sed s/tas/cdd/`                        # orig. Roll back to this.
			local ofile_gsl=`echo $ofile | sed s/tas/gsl/`                        # orig. Roll back to this. 

			#ofile_tas_annual=`echo $ofile | sed s/tg/tg_annual-mean/`      # Testing senorge
			#ofile_tas_seasonal=`echo $ofile | sed s/tg/tg_seasonal-mean/`  # Testing senorge 

			#ofile_growing=`echo $ofile | sed s/tg/growing/`                 # Testing senorge: vekstsesong

			# for first year (i.e. count==0); make list of ofilenames, where the year and file format is removed from each name. 
			if [ $count == 0 ]; then
				get_filenamestart $ofile_tas_annual $yyyy
				ofilestartlist="$ofilestartlist $filestart"
				
				get_filenamestart $ofile_tas_seasonal $yyyy
				ofilestartlist="$ofilestartlist $filestart"
			fi


			# echo "ofile is" $ofilelist
			# cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_1993.nc4
			# ofile_tas_annual=`echo $ofile | sed s/tas/tas_annual-mean/`

	 
			# I guess it would make sense to crop the domain to mainland Norway before processing? I've added "-ifthen $landmask" in the lines below.
			# Are there better ways to crop to the landmask? This is what "ifthen $landmask" does:
			# cdo ifthen $landmask $filedir/$file '$filedir/$file_mainland_norway.nc4' 

			# vekstsesongens lengde, Mean annual growing season (days>=5C). Merk at senorge er i degC, derfor terskel på 5, ikke 278.15.
			# mkdir -p "./senorge/growing/"                                                           # Testing senorge
			# echo "Ofile_growing=" ."/senorge/growing/"$ofile_growing
			# cdo timsum -gec,5 -ifthen $landmask $filedir/$ofile ."/senorge/growing/"$ofile_growing  # med senorge-data må file være ofile!
			# trenger ikke månedsverdier:
			# cdo monsum -gec,5 -ifthen $landmask $filedir/$ofile ."/senorge/growing/"$ofile_growing  # gir store månedsverdifiler.

			#ncatted -O -a tracking_id,global,o,c,`uuidgen` 		                                ."/senorge/growing/"$ofile_growing
			#ncatted -O -a standard_name,tg,o,c,"spell_length_of_days_with_air_temperature_above_threshold" ."/senorge/growing/"$ofile_growing
			#ncatted -O -a units,tg,o,c,"day" 		  		                                ."/senorge/growing/"$ofile_growing 
			#ncatted -O -a long_name,tg,o,c,"Mean annual growing season length (days TAS >=5 °C)"           ."/senorge/growing/"$ofile_growing
			##ncatted -O -a short_name,tg,o,c,"growing"                                                   ."/senorge/growing/"$ofile_growing
				## ncrename -v tg,growing .'/senorge/growing/'$ofile_growing .'/senorge/growing/'$ofile_growing

				# Compute annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_tas_annual ]; then   # check if the file exists

				echo $ofile_tas_annual
				pwd

				cdo timmean   -ifthen $landmask $filedir/$file  ./$RCM/$VAR/$ofile_tas_annual

				ncatted -O -a tracking_id,global,o,c,`uuidgen` 		         ./$RCM/$VAR/$ofile_tas_annual
				ncatted -O -a long_name,tas,o,c,"annual average_of_air_temperature" ./$RCM/$VAR/$ofile_tas_annual
				## ncrename -v tas,annual_avg_air_temperature ./$RCM/$VAR/$ofile_tas_annual ./$RCM/$VAR/$ofile_tas_annual

				echo "done adding metadata to the annual file. Proceed to seasonal."

			else
				echo "file" ./$RCM/$VAR/$ofile_tas_annual "already exists. Skipping computations."
			fi
	    
 			if ! [ -f ./$RCM/$VAR/$ofile_tas_seasonal ]; then
				# cdo yseasmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_tas_seasonal
				cdo -L timmean -selmon,12,1,2 -ifthen $landmask $filedir/$file ./$RCM/$VAR/"DJFmean.nc"
				cdo -L timmean -selmon,3/5    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"MAMmean.nc"
				cdo -L timmean -selmon,6/8    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"JJAmean.nc"
				cdo -L timmean -selmon,9/11   -ifthen $landmask $filedir/$file ./$RCM/$VAR/"SONmean.nc"
				cdo cat ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" ./$RCM/$VAR/$ofile_tas_seasonal
				rm ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" 
				# Trenger kanskje ikke rm, for den blir overskrevet uansett hvert år? 

				ncatted -O -a tracking_id,global,o,c,`uuidgen` 		       ./$RCM/$VAR/$ofile_tas_seasonal
				ncatted -O -a long_name,tas,o,c,"seasonal average_of_air_temperature" ./$RCM/$VAR/$ofile_tas_seasonal
				## ncrename -v tas,seasonal_avg_air_temperature ./$RCM/$VAR/$ofile_tas_seasonal ./$RCM/$VAR/$ofile_tas_seasonal	 
			else
				echo "file" ./$RCM/$VAR/$ofile_tas_seasonal "already exists. Skipping computations."

			fi 
	 
 	 
	 
		# vekstsesongens lengde
		# Denne er tricky fordi den skal beregnes fra en glattet kurve.
		# Fra dynamisk dokument: "Midlere vekstsesong i 30-års perioder gjøres utfra glattet kurve for temperaturutvikling gjennom året." 
		# den også tar inn filbane til landmaske. Og den skjønner ikke at jeg prøver å gi den to inputargumenter.
		# cdo eca_gsl $file $landmask -gec,20 $file $RCM/$VAR/$ofile_gsl

		# vinter- og sommersesong inn her?

		# Avkjølingsgraddager, cooling days
		# Antall dager med TAM>=22 (gec) over året

		#cdo -s monsum -setrtoc,-Inf,0,0 -subc,295.15 -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_cdd

		#ncatted -O -a tracking_id,global,o,c,`uuidgen` 		  ./$RCM/$VAR/$ofile_cdd 
		#ncatted -O -a short_name,tas,o,c,"cdd" 		          ./$RCM/$VAR/$ofile_cdd
		#ncatted -O -a units,tas,o,c,"degreedays" 			  ./$RCM/$VAR/$ofile_cdd
		#ncatted -O -a long_name,tas,o,c,"cooling_degree-days"           ./$RCM/$VAR/$ofile_cdd


		# elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ] || [ $VAR == "tx" ] || [ $VAR == "tn" ]; then   # Testing senorge
		elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ]; then             # orig. Roll back to this.

			#set tasmin to tasmax because they are treated in the same way
			VAR="tasmax"      # set the first variable is tasmax and treat tasmin equally.  # orig. Roll back to this.
			#VAR="tx"          # Testing senorge

				echo ""
			echo "tasmax chosen (and tasmin automatically read in). Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."

			# Gjennomsnitt av tasmax
			mkdir -p  $RCM/tasmax/
			local ofile_tasmax_annual=`echo $ofile | sed s/tasmax/tasmax_annual-mean/`
			local ofile_tasmax_seasonal=`echo $ofile | sed s/tasmax/tasmax_seasonal-mean/`	 
			#ofile_tasmax_monmean=`echo $ofile | sed s/tasmax/tasmax_monmean/`
			#ofile_tasmin_monmean=`echo $ofile | sed s/tasmax/tasmin_monmean/`

			#ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`
			#ofile_dzc=`echo $ofile | sed s/tasmax/dzc/`
			local ofile_fd=`echo $ofile | sed s/tasmax/fd/`
			local ofile_tropnight=`echo $ofile | sed s/tasmax/tropnight/`
			local ofile_norheatwave=`echo $ofile | sed s/tasmax/norheatwave/`
			local ofile_summerdnor=`echo $ofile | sed s/tasmax/summerdnor/`
			local ofile_summerd=`echo $ofile | sed s/tasmax/summerd/`


			# cdo ifthen $landmask -monmean ./$RCM/'/mergetime_norheatwave_'$refbegin'-'$refend'.nc'     ./$RCM'/land_tasmax'
			# cdo ifthen $landmask -monmean ./$RCM/'/mergetime_norheatwave_'$refbegin'-'$refend'.nc'     ./$RCM'/land_norheatwave'
				
	 
			# Annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_tasmax_annual ]; then   # check if the file exists
				cdo timmean                -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_tasmax_annual
				# flytt metadata hit når de er klare?
			fi
	 
			if ! [ -f ./$RCM/$VAR/$ofile_tasmax_seasonal ]; then   # check if the file exists

				cdo timmean -selmon,12,1,2 -ifthen $landmask $filedir/$file ./$RCM/$VAR/"DJFmean.nc"
				cdo timmean -selmon,3/5    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"MAMmean.nc"
				cdo timmean -selmon,6/8    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"JJAmean.nc"
				cdo timmean -selmon,9/11   -ifthen $landmask $filedir/$file ./$RCM/$VAR/"SONmean.nc"

				cdo cat ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" ./$RCM/$VAR/$ofile_tas_seasonal
				rm ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc"
				# flytt metadata hit når de er klare?
			fi
	 
			# Monthly mean of $VAR (no space to save this for all variables and models)	 
			# cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/tasmax/$ofile_tasmax_monmean

			# Read in tasmin
			local ifileN=`echo $file | sed s/tasmax/tasmin/`
			local ifiledirN=`echo $filedir | sed s/tasmax/tasmin/`
			echo $ifiledirN/$ifileN

			# Gjennomsnitt av tasmin
			mkdir -p  $RCM/tasmin/
			local ofile_tasmin_annual=`echo $ofile | sed s/tasmax/tasmin_annual-mean/`
			local ofile_tasmin_seasonal=`echo $ofile | sed s/tasmax/tasmin_seasonal-mean/`	 

			# Annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_tasmin_annual ]; then   # check if the file exists
				cdo timmean                -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_tasmin_annual
				# flytt metadata hit når de er klare?
			fi
	 
			if ! [ -f ./$RCM/$VAR/$ofile_tasmin_seasonal ]; then   # check if the file exists
	     
				#cdo timmean                -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_tas_annual

				cdo timmean -selmon,12,1,2 -ifthen $landmask $filedir/$file ./$RCM/$VAR/"DJFmean.nc"
				cdo timmean -selmon,3/5    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"MAMmean.nc"
				cdo timmean -selmon,6/8    -ifthen $landmask $filedir/$file ./$RCM/$VAR/"JJAmean.nc"
				cdo timmean -selmon,9/11   -ifthen $landmask $filedir/$file ./$RCM/$VAR/"SONmean.nc"
				cdo cat ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc" ./$RCM/$VAR/$ofile_tas_seasonal
				rm ./$RCM/$VAR/"DJFmean.nc" ./$RCM/$VAR/"MAMmean.nc" ./$RCM/$VAR/"JJAmean.nc" ./$RCM/$VAR/"SONmean.nc"

				# Monthly mean of $VAR (no space to save this for all variables and models)
				# cdo -s monmean -ifthen $landmask $ifiledirN/$ifileN ./$RCM/tasmin/$ofile_tasmin_monmean
				echo "Tasmin: done"
				# flytt metadata hit når de er klare?
			fi
	 

			# DTR
			if ! [ -f ./$RCM/$VAR/$ofile_dtr ]; then   # check if the file exists

				#ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`  # <- this is written higher up
				mkdir -p  $RCM/dtr/
				local ofile_dtr_annual=`echo $ofile | sed s/tasmax/dtr_annual-mean/`
				local ofile_dtr_seasonal=`echo $ofile | sed s/tasmax/dtr_seasonal-mean/`	 
				#ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`

				echo "Ofile_dtr=" $RCM"/dtr/"$ofile_dtr	 
				cdo sub -ifthen $landmask $filedir/$file $ifiledirN/$ifileN ./$RCM/dtr/$ofile_dtr
			fi

	 	 
			# DZC, nullgradspasseringer
			if ! [ -f ./$RCM/$VAR/$ofile_dzc ]; then   # check if the file exists
				mkdir -p  $RCM/dzc/
				local ofile_dzc_annual=`echo $ofile | sed s/tasmax/dzc_annual-mean/`
				local ofile_dzc_seasonal=`echo $ofile | sed s/tasmax/dzc_seasonal-mean/`	 
				echo "Ofile_dzc=" $RCM"/dzc/"$ofile_dzc	 
				cdo monsum -mul -ltc,273.15 -ifthen $landmask $ifiledirN/$ifileN -gtc,273.15 -ifthen $landmask $filedir/$file ./$RCM/dzc/$ofile_dzc
			fi


			# Frostdager, fd # under 0 grader
			if ! [ -f ./$RCM/$VAR/$ofile_fd ]; then   # check if the file exists
				mkdir -p $RCM/fd/
				echo "Ofile_fd=" $RCM"/fd/"$ofile_fd
				cdo monsum -ltc,273.15 -ifthen $landmask $ifiledirN/$ifileN ./$RCM/fd/$ofile_fd
			fi
	 
	 
			# tropenattdøgn # Tmin >= 20 grader
			if ! [ -f ./$RCM/$VAR/$ofile_tropnight ]; then   # check if the file exists
				mkdir -p $RCM/tropnight/
				echo "Ofile_tropnight=" $RCM"/tropnight/"$ofile_tropnight
				cdo -s monsum -gec,293.15 -ifthen $landmask $ifiledirN/$ifileN ./$RCM/tropnight/$ofile_tropnight
			fi
	 
			# Nordiske sommerdager # over 20 grader
			if ! [ -f ./$RCM/$VAR/$ofile_norsummer ]; then   # check if the file exists
				mkdir -p  $RCM/norsummer/
				echo "Ofile_norsummer=" $RCM"/norsummer/"$ofile_norsummer	 	 
				cdo monsum -gec,293.15 -ifthen $landmask $filedir/$file ./$RCM/norsummer/$ofile_norsummer
			fi

			# Nordiske sommerdager # over 25 grader
			if ! [ -f ./$RCM/$VAR/$ofile_summerdays ]; then   # check if the file exists
				mkdir -p  $RCM/summerdays/	 
				echo "Ofile_summerdays=" $RCM"/summerdays/"$ofile_summerdays 	 
				cdo monsum -gec,298.15 -ifthen $landmask $filedir/$file ./$RCM/summerdays/$ofile_summerdays
			fi
	 
			# norsk hetebølge # over 27 grader
			#ofile_norheatwave=`echo $ofile | sed s/tasmax/norheatwave/`
			if ! [ -f ./$RCM/$VAR/$ofile_norheatwave ]; then   # check if the file exists
				mkdir -p $RCM/norheatwave/
				cdo monsum -gec,300.15 -runmean,5 -ifthen $landmask $filedir/$file ./$RCM/norheatwave/$ofile_norheatwave 
				echo "norsk hetebølge: done"
			fi    

			# Generate UUID
			# uuid10=$(python -c 'import uuid; print(uuid.uuid4())')
			# ncatted -O -a id,global,o,c,$uuid2  ./$RCM/tasmin/$ofile_tasmax_monmean 

			# Endre til: ncatted -O -a tracking_id,global,o,c,`uuidgen`

			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/tasmax/$ofile_tasmax
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/tasmin/$ofile_tasmin
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/dtr/$ofile_dtr
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/dzc/$ofile_dzc
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/fd/$ofile_fd
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/tropnight/$ofile_tropnight 	
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/norsummer/$ofile_norsummer
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/summerdays/$ofile_summerdays
			ncatted -O -a tracking_id,global,o,c,`uuidgen`    ./$RCM/norheatwave/$ofile_norheatwave 

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
			echo "pr chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."

			# Sum av pr
			local ofile_pr_annual=`echo $ofile | sed s/pr/pr_annual-sum/`
			local ofile_pr_seasonal=`echo $ofile | sed s/pr/pr_seasonal-sum/`

			# Annual and seasonal mean of $VAR
			if ! [ -f ./$RCM/$VAR/$ofile_pr_annual ]; then   # check if the file exists
				cdo timmean                -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_annual

			fi

			if ! [ -f ./$RCM/$VAR/$ofile_pr_seasonal ]; then   # check if the file exists
	     
				cdo timmean -selmon,12,1,2 -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_DJFsum
				cdo timmean -selmon,3/5    -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_MAMsum
				cdo timmean -selmon,6/8    -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_JJAsum
				cdo timmean -selmon,9/11   -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_SONsum

			fi
	 
			# Monthly sum of $VAR (no space to save this for all variables and models)
			#cdo -s monsum -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_pr_monsum
			## cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_pr_monmean	 

			#ncatted -O -a tracking_id,global,o,c,`uuidgen` 	./$RCM/$VAR/$ofile_pr_monsum
			#ncatted -O -a short_name,pr,o,c,"pr_monsum" 	        ./$RCM/$VAR/$ofile_pr_monsum
			##ncatted -O -a short_name,pr,o,c,"pr_monmean" 		./$RCM/$VAR/$ofile_pr_monmean	 
			#ncatted -O -a units,pr,o,c,"kg m-2 month-1"  		./$RCM/$VAR/$ofile_pr_monsum
			#ncatted -O -a long_name,pr,o,c,"sum_of_precipitation"	./$RCM/$VAR/$ofile_pr_monsum


		# elif [ $VAR == "hurs" ]; then
			# 	 echo ""
			#    echo "hurs chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_hurs_monmean=`echo $ofile | sed s/hurs/hurs_monmean/`	 

			# 	 # Monthly mean av hurs
			#    cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_hurs_monmean	 

			# 	 ncatted -O -a tracking_id,global,o,c,`uuidgen` 		                ./$RCM/$VAR/$ofile_hurs_monmean
			# 	 ncatted -O -a short_name,hurs,o,c,"hurs_monmean" 		                ./$RCM/$VAR/$ofile_hurs_monmean	 
			# 	 ncatted -O -a units,hurs,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_hurs_monmean
			# 	 ncatted -O -a long_name,hurs,o,c,"surface_downwelling_shortwave_flux_in_air"	./$RCM/$VAR/$ofile_hurs_monmean


		# elif [ $VAR == "rlds" ]; then
			# 	 echo ""
			#    echo "rlds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rlds_monmean=`echo $ofile | sed s/rlds/rlds_monmean/`	 
			
			# 	 # Monthly mean av rlds
			#    cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_rlds_monmean	 
			
			# 	 ncatted -O -a tracking_id,global,o,c,`uuidgen` 	 	                ./$RCM/$VAR/$ofile_rlds_monmean
			# 	 ncatted -O -a short_name,rlds,o,c,"rlds_monmean"                  	        ./$RCM/$VAR/$ofile_rlds_monmean	 
			# 	 ncatted -O -a units,rlds,o,c,"W m-2" 		                        ./$RCM/$VAR/$ofile_rlds_monmean
			# 	 ncatted -O -a long_name,rlds,o,c,"surface_downwelling_longwave_flux_in_air"	./$RCM/$VAR/$ofile_rlds_monmean


		#  elif [ $VAR == "rsds" ]; then
			# 	 echo ""
			#    echo "rsds chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_rsds_monmean=`echo $ofile | sed s/rsds/rsds_monmean/`	 
			
			# 	 # Monthly mean av rsds
			#    cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_rsds_monmean	 
			
			# 	 ncatted -O -a tracking_id,global,o,c,`uuidgen`           ./$RCM/$VAR/$ofile_rsds_monmean
			# 	 ncatted -O -a short_name,rsds,o,c,"rsds_monmean"         ./$RCM/$VAR/$ofile_rsds_monmean	 
			# 	 ncatted -O -a units,rsds,o,c,"%"                         ./$RCM/$VAR/$ofile_rsds_monmean
			# 	 ncatted -O -a long_name,rsds,o,c,"relative humidity"     ./$RCM/$VAR/$ofile_rsds_monmean

			
		#  elif [ $VAR == "ps" ]; then
			# 	 echo ""
			#    echo "ps chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_ps_monmean=`echo $ofile | sed s/ps/ps_monmean/`	 
			
			# 	 # Monthly mean av ps
			#    cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_ps_monmean	 
			
			# 	 ncatted -O -a tracking_id,global,o,c,`uuidgen` 	./$RCM/$VAR/$ofile_ps_monmean
			# 	 ncatted -O -a short_name,ps,o,c,"ps_monmean" 		./$RCM/$VAR/$ofile_ps_monmean	 
			# 	 ncatted -O -a units,ps,o,c,"Pa" 		        ./$RCM/$VAR/$ofile_ps_monmean
			# 	 ncatted -O -a long_name,ps,o,c,"surface_air_pressure"	./$RCM/$VAR/$ofile_ps_monmean



		#  elif [ $VAR == "sfcWind" ]; then
			# 	 echo ""
			#    echo "sfcWind chosen. Now processing file " $file ", which is number " $count " out of " $nbrfiles " (from one model, RCM and RCP only)."
			# 	 ofile_sfcWind_monmean=`echo $ofile | sed s/sfcWind/sfcWind_monmean/`	 
			
			# 	 # Monthly mean av sfcWind
			#    cdo -s monmean -ifthen $landmask $filedir/$file ./$RCM/$VAR/$ofile_sfcWind_monmean	 
			
			# 	 ncatted -O -a tracking_id,global,o,c,`uuidgen` 	./$RCM/$VAR/$ofile_sfcWind_monmean
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

function calc_periodmeans {
    # This function do mergetime and timmean over all selected years for annual indices. It needs several arguments in correct order:
    #   $1 = reffbegin or scenbegin
    #   $2 = refend or scenend
    #   $remaining = list of each substring common for all files for multiple years for which timmean should be computed
    #       A substring can be e.g. "cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_" (where the year and .nc(4) is removed)
    echo ""
    echo "In function computing mean over period"
    

    # make list of years:
    local period="$1-$2"
    local yearlist="$(seq $1 $2)"
    local yeararray=($yearlist)

    local ifilestartlist=${@:3}
    local ipath=$workdir/$RCM/$VAR/
    local opath=$workdir/tmp/$USER/$RCM/$VAR/
    mkdir -p $opath
    
	ofilelist=""
    # calc period mean for each ifilestart string
    for ifilestart in $ifilestartlist
    do
        local ifilepathlist_periodyears=( "${yeararray[@]/#/$ipath$ifilestart}" )
        local ifilepathlist_periodyears="${ifilepathlist_periodyears[@]/%/.nc4}"

        ofilepath1="$opath$ifilestart$period.nc4"
        ofilepath2="$opath$ifilestart${period}_periodmean.nc4"
        if ! [ -f $ofilepath1 ]; then   # if ofile not already exist, do mergetime
            cdo mergetime $ifilepathlist_periodyears $ofilepath1
            echo Saved: "$(basename $ofilepath1)"
        fi
        if ! [ -f $ofilepath2 ]; then   # if ofile not already exist, do timmean
			cdo yseasmean $ofilepath1 $ofilepath2 #yseasmean (instead of timmean) makes the mean calculation work for both annual and seasonal data.
            echo Saved: "$(basename $ofilepath2)"
        fi
		ofilelist="$ofilelist $ofilepath2"
    done
    echo ""

} 

### Main script
#Save current dir for return point
currdir=$PWD
echo "Current directory" $currdir
echo "Workdir directory" $workdir

#Check provision of varname
if [ -z "$VAR" ]; then
	echo "Error: No variable specified! Add using --var varname."
	exit 1
fi



# VAR=$1   # note: not to be confused with $1 in the functions. This is the input argument to calc_generalised_indices.sh
# DISK=$2  # hmdata on NVE or lustre on MET. Use HOSTNAME instead.



if [ $HOSTNAME == "l-klima-app05" ]; then      # if DISK="hmdata"
	echo ""
	echo "Running from " $HOSTNAME
	workdir=/hdata/hmdata/KiN2100/analyses/indicators/calc_gen_indices/
	filedir_EQM=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/eqm/netcdf
	filedir_3DBC=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/3dbc-eqm/netcdf
	filedir_senorge=/hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf
	landmask=/hdata/hmdata/KiN2100/analyses/github/KiN2100/geoinfo/kss2023_mask1km_norway.nc4 # from our github repo
	#    filedir_3DBC_rcp45=$filedir_3DBC/$RCM/$VAR/rcp45/
elif [ $HOSTNAME == "lustre" ]; then
	echo ""
	echo "Running from " $HOSTNAME
	workdir=/lustre/storeC-ext/users/kin2100/NVE/analyses/calc_indices/ #
	## workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc/test_ibni
	filedir_EQM=/lustre/storeC-ext/users/kin2100/NVE/EQM/  # $RCM/$VAR/hist/
	filedir_3DBC=/lustre/storeC-ext/users/kin2100/MET/3DBC/application/ #$RCM/$VAR/hist/
	#filedir_senorge=/lustre/storeA/project/metkl/senorge2/archive/seNorge_2018_v20_05 # <- check filepath! 
	#    filedir_3DBC_rcp45=$filedir_3DBC/$RCM/$VAR/rcp45/    
	landmask=/lustre/storeC-ext/users/kin2100/NVE/analyses/kss2023_mask1km_norway.nc4
    
fi


echo "Workdir directory" $workdir
#go to working dir
mkdir -p $workdir
cd $workdir

mkdir -p tmp/$USER
### seNorge 2018 v20.05
# For the historical period (DP1), we need to process seNorge data. # Testing senorge
# calc_indices $filedir_senorge        # files on the form tg_senorge2018_1957.nc or senorge2018_RR_1957.nc

  
#get list of RCMs
#RCMLIST=`ls $filedir_EQM`
#RCMLIST=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/`

echo "Found the following RCMs:"
echo ${rcmlist[@]}
#echo $RCMLIST | tr " " "\n"
echo -ne "======================"

echo "Check if index files have already been created before computing indices (if needed)."

if [ $VAR == "tas" ] || [ $VAR == "pr" ]; then
	last_output_file=$workdir'/'${rcmlist[${#rcmlist[@]} - 1]}'/'$VAR'/noresm-r1i1p1-remo_rcp45_3dbc-eqm-sn2018v2005_rawbc_norway_1km_'$VAR'_annual-mean_2098.nc4'
	#last_output_file=$workdir'/cnrm-r1i1p1-aladin/'$VAR'/cnrm-r1i1p1-aladin_hist_eqm-sn2018v2005_rawbc_norway_1km_tas_annual-mean_1961.nc4' #<-first 
	#last_input_file=$filedir_3DBC'/noresm-r1i1p1-remo/'$VAR'/rcp45/noresm-r1i1p1-remo_rcp45_3dbc-eqm-sn2018v2005_rawbc_norway_1km_'$VAR'_daily_2098.nc4'
	echo ""   # Blank line (or print $last_output_file)
	# NOTE: I have tried replacing noresm with ${RCMLIST[9]}, but ALL RCMs are contained in ${RCMLIST[0]}, for some reason...
elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ]; then
	last_output_file=$workdir'/noresm-r1i1p1-remo/'$VAR'/noresm-r1i1p1-remo_rcp45_3dbc-eqm-sn2018v2005_rawbc_norway_1km_dtr_2098.nc4'
	# eller tasmax_annual-mean
	#last_input_file=$filedir_3DBC'/noresm-r1i1p1-remo/dtr/rcp45/noresm-r1i1p1-remo_rcp45_3dbc-eqm-sn2018v2005_rawbc_norway_1km_dtr_daily_2098.nc4'
else
	echo "This if clause must be extended with the chosen variable."
fi



for RCM in $rcmlist  #$RCMLIST
do
	### EQM
	echo -ne "\n\nProcessing" $RCM "EQM" $VAR "\n"
	mkdir -p $RCM/$VAR

	#HIST
	calc_indices $filedir_EQM/$RCM/$VAR/hist/
	calc_periodmeans $refbegin $refend $ofilestartlist # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
	ofilelist_hist=($ofilelist)
	echo "done hist period means"

	#calc_indices $filedir_EQM_hist
	## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/hist/

	#RCP2.6
	calc_indices $filedir_EQM/$RCM/$VAR/rcp26/
	calc_periodmeans $scenbegin $scenend $ofilestartlist  # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
	ofilelist_rcp26=($ofilelist)
	echo ""
	echo "done rcp2.6 period means"
	## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp26/

	#RCP4.5
	calc_indices $filedir_EQM/$RCM/$VAR/rcp45/
	calc_periodmeans $scenbegin $scenend $ofilestartlist  # ofilestartlist is made in calc_indices, and can be printed using: echo ${ofilestartlist[@]}
	ofilelist_rcp45=($ofilelist)
	echo ""
	echo "done rcp4.5 period means"
	## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp45/

	# ---------- Computing difference ---------- #
	echo ""
	echo "EQM files: Computing change = scenario - historical"
	for (( i=0; i<${#ofilelist_hist[@]}; i++ ))
	do
		ifile_hist=${ofilelist_hist[$i]}
		ifile_rcp26=${ofilelist_rcp26[$i]}
		ifile_rcp45=${ofilelist_rcp45[$i]}
		ofile_rcp26_minus_hist=`echo $ifile_rcp26 | sed s/_periodmean/_periodmean_minus_hist${refbegin}-${refend}_periodmean/`
		ofile_rcp45_minus_hist=`echo $ifile_rcp45 | sed s/_periodmean/_periodmean_minus_hist${refbegin}-${refend}_periodmean/`

		echo "Index $i"
		echo "	ifile_hist:        $(basename $ifile_hist)"
		echo "	ifile_rcp2.6:      $(basename $ifile_rcp26)"
		echo "	ofile_rcp2.6-hist: $(basename $ofile_rcp26_minus_hist)"
		echo "	ofile_rcp4.5-hist: $(basename $ofile_rcp45_minus_hist)"

		cdo sub $ifile_rcp26 $ifile_hist $ofile_rcp26_minus_hist
		cdo sub $ifile_rcp45 $ifile_hist $ofile_rcp45_minus_hist
	done
	# ------------------------------------------ #
	exit

	### 3DBC
	echo -ne "\n\nProcessing" $RCM "3DBC" $VAR "\n"

	#HIST
	calc_indices $filedir_3DBC/$RCM/$VAR/hist/ 
	##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/$VAR/hist/

	#RCP2.6
	calc_indices $filedir_3DBC/$RCM/$VAR/rcp26/
	##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/$VAR/rcp26/

	# RCP4.5
	calc_indices $filedir_3DBC/$RCM/$VAR/rcp45/
	##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/$VAR/rcp45/

done


# Continue here. The rest of the script is a proof-of-concept, outlining the order of commands, but they do not run.
# Before they can run, there many special cases to treat: variable names/metadata, year selection, the fact that models cover different years etc.  


#if [ "$VAR" == "tas" ] || [ "$VAR" == "tg" ]; then    # Testing seNorge
if [ $VAR == "tas" ]; then                          

	# These lines do not run yet. They serve as inspiration.
	#cdo mergetime $workdir/$RCM/$VAR/*'_tas_annual-mean.nc'   $workdir/tmp/$USER/$RCM/$VAR/'tas_annual-mean_mergetime_'$refbegin'-'$refend'.nc'
	#cdo mergetime $workdir/$RCM/$VAR/*'_tas_seasonal-mean.nc' $workdir/tmp/$USER/$RCM/$VAR/'tas_seasonal-mean_mergetime_'$refbegin'-'$refend'.nc'


	# Then compute the 30-year means. Must adjust the timesteps according to the period.
	# cdo timmean -selyear,$refbegin/$refend $workdir/tmp/$USER/$RCM/$VAR/'tas_annual-mean_mergetime_'$refbegin'-'$refend'.nc'     $workdir/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$refbegin'-'$refend'.nc' 
	# cdo timmean -selyear,$refbegin/$refend $workdir/tmp/$USER/$RCM/$VAR/'tas_seasonal-mean_mergetime_'$refbegin'-'$refend'.nc'   $workdir/$RCM/$VAR'/tas_seasonal-mean_30-yrmean_mgtim_'$refbegin'-'$refend'.nc' 
	# cdo timmean -selyear,$scenbegin/$scenend $workdir/tmp/$USER/$RCM/$VAR/'tas_annual-mean_mergetime_'$scenbegin'-'$scenend'.nc'   $workdir/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$scenbegin'-'$scenend'.nc' 	   
	# cdo timmean -selyear,$scenbegin/$scenend $workdir/tmp/$USER/$RCM/$VAR/'tas_seasonal-mean_mergetime_'$scenbegin'-'$scenend'.nc'   $workdir/$RCM/$VAR'/tas_seasonal-mean_30-yrmean_mgtim_'$scenbegin'-'$scenend'.nc'


	# Change the name of the file and the variable name as shown in ncview:
	# See filename convensions in the modelling protocol, chapter 7.6. https://docs.google.com/document/d/1V9RBqdqUrMOYqfMVwcSHRwWP57fiS3R8/edit
	# Note here that bias-baseline could be either "eqm-sn2018v2005" or "3dbc-eqm-sn2018v2005", depending on the bias-adjustment method.
	## ncrename -v tas,tas_annual-mean  $workdir/$RCM/$VAR'/tas_annual-mean_30-yrmean_mgtim_'$refbegin'-'$refend'.nc' $workdir/$RCM/$VAR/$RCM_$RCP_eqm-sn2018v2005_none_norway_1km_tas_annual-mean_'$refbegin'-'$refend'.nc'


elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ]; then 
	# elif [ $VAR == "tasmax" ] || [ $VAR == "tasmin" ] || [ $VAR == "tx" ] || [ $VAR == "tn" ]; then   # Testing senorge

	# Does not run! 
	cdo mergetime $workdir/$RCM/$VAR/*'_tasmax_annual-mean.nc'   $workdir/tmp/$USER/'tasmax_annual-mean_mergetime_'$refbegin'-'$refend'.nc'
	cdo mergetime $workdir/$RCM/$VAR/*'_tasmax_seasonal-mean.nc' $workdir/tmp/$USER/'tasmax_seasonal-mean_mergetime_'$refbegin'-'$refend'.nc'
	cdo mergetime $workdir/$RCM/$VAR/*'_tasmin_annual-mean.nc'   $workdir/tmp/$USER/'tasmin_annual-mean_mergetime_'$refbegin'-'$refend'.nc'
	cdo mergetime $workdir/$RCM/$VAR/*'_tasmin_seasonal-mean.nc' $workdir/tmp/$USER/'tasmin_seasonal-mean_mergetime_'$refbegin'-'$refend'.nc'


elif [ $VAR == "pr" ]; then

	#cdo mergetime $workdir/$RCM/$VAR/*'_tas_annual-mean.nc' $workdir/tmp/$USER/$RCM/$VAR/'tas_annual-mean_mergetime_'$refbegin'-'$refend'.nc'
	#cdo mergetime $workdir/$RCM/$VAR/*'_tas_seasonal-mean.nc' $workdir/tmp/$USER/$RCM/$VAR/'tas_seasonal-mean_mergetime_'$refbegin'-'$refend'.nc'

fi
       
	   
# cdo mergetime senorge/growing/'growing_'*'.nc' senorge/growing'/growing_mergetime_timsum_1957-2020.nc'  #'$refbegin'-'$refend'.nc'   # Testing senorge
#cdo timmean -seltimestep,5/34  .'/senorge/growing/growing_mergetime_timsum_1957-2020.nc' .'/senorge/growing/growing_30-yrmean_mgtim_1961-1990.nc'
#cdo timmean -seltimestep,35/64 .'/senorge/growing/growing_mergetime_timsum_1957-2020.nc' .'/senorge/growing/growing_30-yrmean_mgtim_1991-2000.nc'
#ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1961-1990.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1961-1990.nc4'
#ncrename -v tg,growing .'/senorge/growing/growing_30-yrmean_mgtim_1991-2000.nc' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1991-2020.nc4'

echo 'Computing differences by subtracting the reference period.' # For senorge that means the difference between 91-2020 and 61-90.

#cdo sub .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1991-2020.nc4' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_growing_annual-mean_1961-1990.nc4' .'/senorge/growing/sn2018v2005_hist_none_none_norway_1km_diff-growing_annual-mean_1991-2020_minus_1961-1990.nc4'



#  for pctls in 10 25 50 75 90; do
#     cdo enspctl,$pctls  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc'
	
#     cdo fldmean $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'
	
#     echo 
#     echo 'Printing fieldmean for 1991-2020, enspctl=' $enspctl
#     echo 
	
#     cdo info $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'

# done   # Done looping over percentiles: 10,25,50,75,90

#done


echo "Add this when you have double-checked rm tmp/$USER/mergetime*"

#return to starting dir
cd $PWD




echo -ne "\n=====\nDone!\n"
