#!/bin/bash

##!/usr/bin/bash   # <- use this on Lustre
set -e #exit on error

## Script to calculate monthly means of the bias-adjusted RCM data
#
# EQM and 3DBC
# Hist, rcp26 and rcp45 so far, ssp3.70 to follow
#
# Call: ./calc_generalised_indices.sh VAR 
# where VAR is one of hurs, pr, ps, rlds, rsds, sfcWind, tas, tasmax, tasmin; later also mrro (runoff), swe (snow), esvpbls (evapotranspiration), soilmoist (soil moisture deficit).
#
#
# Run from workdir=/hdata/hmdata/KiN2100/analyses/indicators/calc_gen_indices/
# NOT workdir=/lustre/storeC-ext/users/kin2100/NVE/analyses/calc_gen_indices # foreløpig: test_ibni
# NOT workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc
                   


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


function calc_indices {       # two input arguments:  filedir and $landmask
   # på formen /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/$1/*`
    count=0
    filedir=$1
    if [ $HOSTNAME == "l-klima-app05" ]; then      # if DISK="hmdata"
	echo $HOSTNAME
	landmask=/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4
    else
        landmask=/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4	
    fi
    
    echo "Filedir = " $filedir
    #echo $RCM/$VAR/$ofile_tas_monmean
    filelist=`ls $1`
    nbrfiles=`echo $filelist | wc -w`
    # landmask=$2    <- This does not seem to work, so I have harcoded NVE's path:

    echo "Test " $landmask
    echo "Processing " $1
    echo "Processing " $nbrfiles " files"

   
   for file in $filelist
      do ofile=`basename $file | sed s/daily/monthly/`
         #echo "Ofile is: " $ofile
	 
      if [ $VAR == "tas" ]; then 
	 echo ""
         echo "tas chosen"
	 ofile_tas_monmean=`echo $ofile | sed s/tas/tas_monmean/`
	 ofile_cdd=`echo $ofile | sed s/tas/cdd/`
	 ofile_gsl=`echo $ofile | sed s/tas/gsl/`

	 # Gjennomsnitt av tas
         cdo -s monmean $filedir/$file ./$RCM/$VAR/$ofile_tas_monmean

 	 # Avkjølingsgraddager, cooling days
         # Antall dager med TAM>=22 (gec) over året
	
	 cdo -s monsum -setrtoc,-Inf,0,0 -subc,295.15 $filedir/$file ./$RCM/$VAR/$ofile_cdd

	# vekstsesongens lengde
	# Denne er tricky fordi den også tar inn filbane til landmaske. Og den skjønner ikke at jeg prøver å gi den to inputargumenter.
        # cdo eca_gsl $file $landmask -gec,20 $file $RCM/$VAR/$ofile_gsl
	
	
	
      elif [ $VAR == "tasmax" ]; then 
         echo ""
	 echo "tasmax chosen"
	 echo "File = " $file
	 ofile_tasmax_monmean=`echo $ofile | sed s/tasmax/tasmax_monmean/`
	 ofile_tasmin_monmean=`echo $ofile | sed s/tasmax/tasmin_monmean/`
	 ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`
	 ofile_dzc=`echo $ofile | sed s/tasmax/dzc/`
	 ofile_fd=`echo $ofile | sed s/tasmax/fd/`
	 ofile_tropnight=`echo $ofile | sed s/tasmax/tropnight/`
	 ofile_norheatwave=`echo $ofile | sed s/tasmax/norheatwave/`
	 ofile_summerdnor=`echo $ofile | sed s/tasmax/summerdnor/`
	 ofile_summerd=`echo $ofile | sed s/tasmax/summerd/`
 
	 # Gjennomsnitt av tasmax
	 mkdir -p  $RCM/tasmax/
         cdo -s monmean $filedir/$file ./$RCM/tasmax/$ofile_tasmax_monmean

	 
	 ifileN=`echo $file | sed s/tasmax/tasmin/`
         ifiledirN=`echo $filedir | sed s/tasmax/tasmin/`
	 echo $ifiledirN/$ifileN
	 
 	 # Gjennomsnitt av tasmin
	 mkdir -p  $RCM/tasmin/
         cdo -s monmean $ifiledirN/$ifileN ./$RCM/tasmin/$ofile_tasmin_monmean
	 echo "Tasmin: done"


	 # DTR		
	 #ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`
	 mkdir -p  $RCM/dtr/
	 cdo sub $filedir/$file $ifiledirN/$ifileN ./$RCM/dtr/$ofile_dtr

 	 # Nullgradspasseringer
##        echo "dzc chosen"
##	    filelist_tasmin=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/TASMIN/hist/*`
##	    nbrfiles=`echo $filelist | wc -w`
	 

	 #ofile_dzc=`echo $ofile | sed s/tasmax/dzc/`
	 mkdir -p  $RCM/dzc/
	 cdo monsum -mul -ltc,273.15 $ifiledirN/$ifileN -gtc,273.15 $filedir/$file ./$RCM/dzc/$ofile_dzc


	 # Frostdager, fd # under 0 grader
	 mkdir -p $RCM/fd/
	 cdo monsum -ltc,273.15 $ifiledirN/$ifileN ./$RCM/fd/$ofile_fd

	 
	 # tropenattdøgn # over 20 grader
	 #ofile_tropnight=`echo $ofile | sed s/tasmax/tropnight/`
         mkdir -p $RCM/tropnight/
	 echo "Ofile_tropnight=" $RCM"/tropnight/"$ofile_tropnight
         cdo -s monsum -gec,293.15 $ifiledirN/$ifileN ./$RCM/tropnight/$ofile_tropnight
	 
	 echo "tropenatt: done"

	 
	 # Nordiske sommerdager # over 20 grader
 	 mkdir -p  $RCM/summerdnor/
	 cdo monsum -gec,293.15 $filedir/$file ./$RCM/summerdnor/$ofile_summerdnor
	 

	 # Nordiske sommerdager # over 25 grader
 	 mkdir -p  $RCM/summerd/	 
	 cdo monsum -gec,298.15 $filedir/$file ./$RCM/summerd/$ofile_summerd
	 
	 # norsk hetebølge # over 27 grader
	 #ofile_norheatwave=`echo $ofile | sed s/tasmax/norheatwave/`
         mkdir -p $RCM/norheatwave/
	 cdo monsum -gec,300.15 -runmean,5 $filedir/$file ./$RCM/norheatwave/$ofile_norheatwave 
	 echo "norsk hetebølge: done"


	 # Generate UUID
	 # uuid10=$(python -c 'import uuid; print(uuid.uuid4())')
	 # ncatted -O -a id,global,o,c,$uuid2  ./$RCM/tasmin/$ofile_tasmax_monmean 

	 # Endre til: ncatted -O -a tracking_id,global,o,c,`uuidgen`
  
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/tasmax/$ofile_tasmax_monmean
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/tasmin/$ofile_tasmin_monmean
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/dtr/$ofile_dtr
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/dzc/$ofile_dzc; echo "dzc metadata done"
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/fd/$ofile_fd
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/tropnight/$ofile_tropnight 	
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/summerdnor/$ofile_summerdnor
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/summerd/$ofile_summerd
	 ncatted -O -a tracking_id,global,o,c,`uuidgen` ./$RCM/norheatwave/$ofile_norheatwave 

	 ncatted -O -a short_name,tasmax,o,c,"tasmax"      ./$RCM/tasmax/$ofile_tasmax_monmean
	 ncatted -O -a short_name,tasmin,o,c,"tasmin"      ./$RCM/tasmin/$ofile_tasmin_monmean		
	 ncatted -O -a short_name,tasmax,o,c,"dtr" 	   ./$RCM/dtr/$ofile_dtr
	 ncatted -O -a short_name,tasmin,o,c,"dzc" 	   ./$RCM/dzc/$ofile_dzc 	
	 ncatted -O -a short_name,tasmin,o,c,"fd" 	   ./$RCM/fd/$ofile_fd
	 ncatted -O -a short_name,tasmin,o,c,"tropnight"   ./$RCM/tropnight/$ofile_tropnight 	
	 ncatted -O -a short_name,tasmax,o,c,"summerdnor"  ./$RCM/summerdnor/$ofile_summerdnor
	 ncatted -O -a short_name,tasmax,o,c,"summerd"     ./$RCM/summerd/$ofile_summerd
	 ncatted -O -a short_name,tasmax,o,c,"norheatwave" ./$RCM/norheatwave/$ofile_norheatwave 
 
	 ncatted -O -a units,tasmax,o,c,"C" 	./$RCM/tasmax/$ofile_tasmax_monmean
	 ncatted -O -a units,tasmin,o,c,"C" 	./$RCM/tasmin/$ofile_tasmin_monmean
	 ncatted -O -a units,tasmax,o,c,"C" 	./$RCM/dtr/$ofile_dtr 
	 ncatted -O -a units,tasmin,o,c,"days" 	./$RCM/dzc/$ofile_dzc
	 ncatted -O -a units,tasmin,o,c,"days" 	./$RCM/fd/$ofile_fd
	 ncatted -O -a units,tasmin,o,c,"days" 	./$RCM/tropnight/$ofile_tropnight
	 ncatted -O -a units,tasmax,o,c,"days" 	./$RCM/summerdnor/$ofile_summerdnor
	 ncatted -O -a units,tasmax,o,c,"days" 	./$RCM/summerd/$ofile_summerd	
	 ncatted -O -a units,tasmax,o,c,"number of events" ./$RCM/norheatwave/$ofile_norheatwave
 
	 ncatted -O -a long_name,tasmax,o,c,"average_of_maximum_air_temperature"     ./$RCM/tasmax/$ofile_tasmax_monmean
	 ncatted -O -a long_name,tasmin,o,c,"average_of_minimum_air_temperature"     ./$RCM/tasmin/$ofile_tasmin_monmean 	
	 ncatted -O -a long_name,tasmax,o,c,"diurnal temperature range"  	     ./$RCM/dtr/$ofile_dtr
	 ncatted -O -a long_name,tasmin,o,c,"number_of_days_with_zero_crossings"     ./$RCM/dzc/$ofile_dzc
	 ncatted -O -a long_name,tasmin,o,c,"number_of_frost_days_tasmin-below-0"    ./$RCM/fd/$ofile_fd
	 ncatted -O -a long_name,tasmin,o,c,"number of tropical nights" 	     ./$RCM/tropnight/$ofile_tropnight
	 ncatted -O -a long_name,tasmax,o,c,"nordic_summer_days_tasmax-exceeding-20" ./$RCM/summerdnor/$ofile_summerdnor
	 ncatted -O -a long_name,tasmax,o,c,"summer_days_tasmax-exceeding-20"        ./$RCM/summerd/$ofile_summerd 
	 ncatted -O -a long_name,tasmax,o,c,"norwegian_heatwave_index"               ./$RCM/norheatwave/$ofile_norheatwave	

 
      elif [ $VAR == "pr" ]; then
	 echo ""
         echo "pr chosen"

         #cdo -s monmean $file $RCM/$VAR/$ofile

	 
	 
      fi             # end if VAR
     ((count+=1))
     ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
    done          # end for file in filelist
}                 # end function calc_indices


### Main script
#Save current dir for return point
currdir=$PWD

#Check provision of varname
if [ -z "$1" ]; then
 echo "no variable specified!"
 exit 1
fi



VAR=$1   # note: not to be confused with $1 in the functions. This is the input argument to calc_generalised_indices.sh
# DISK=$2  # hmdata on NVE or lustre on MET. Use HOSTNAME instead.



if [ $HOSTNAME == "l-klima-app05" ]; then
        
    workdir=/hdata/hmdata/KiN2100/analyses/indicators/calc_gen_indices/
    filedir_EQM=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/eqm/netcdf
    filedir_3DBC=/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/3dbc-eqm/netcdf

    landmask=/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4 
    #    filedir_3DBC_rcp45=$filedir_3DBC/$RCM/$VAR/rcp45/
    
elif [ $HOSTNAME == "lustre" ]; then
    
    workdir=/lustre/storeC-ext/users/kin2100/NVE/analyses/test_ibni/ # /analyses/calc_gen_indices
    ## workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc/test_ibni
    filedir_EQM=/lustre/storeC-ext/users/kin2100/NVE/EQM/  # $RCM/$VAR/hist/
    filedir_3DBC=/lustre/storeC-ext/users/kin2100/MET/3DBC/application/ #$RCM/hist/$VAR/

    #    filedir_3DBC_rcp45=$filedir_3DBC/$RCM/rcp45/$VAR/    
    landmask=/lustre/storeC-ext/users/kin2100/NVE/analyses/kss2023_mask1km_norway.nc4
    
fi


#go to working dir
cd $workdir


#get list of RCMs
RCMLIST=`ls $filedir_EQM`
#RCMLIST=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/`

echo "Found the following RCMs:"
echo $RCMLIST | tr " " "\n"
echo -ne "======================"



for RCM in $RCMLIST
do
 ### EQM
 echo -ne "\n\nProcessing" $RCM "EQM" $VAR "\n"
 mkdir -p $RCM/$VAR
 
 #HIST
 
 if [ $HOSTNAME == "l-klima-app05" ]; then 
     calc_indices $filedir_EQM/$RCM/$VAR/hist/
 else 
     calc_indices $filedir_EQM/$RCM/hist/$VAR/
 fi
  #calc_indices $filedir_EQM_hist
  ## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/hist/

  #RCP2.6
  #calc_indices $filedir_EQM_rcp26
  ## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp26/

  #RCP4.5
  #calc_indices $filedir_EQM_hist
  ## calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp45/
 
 ### 3DBC
 echo -ne "\n\nProcessing" $RCM "3DBC" $VAR "\n"

 #HIST
 if [ $HOSTNAME == "l-klima-app05" ]; then 
     calc_indices $filedir_3DBC/$RCM/$VAR/hist/ $landmask
 else
     calc_indices $filedir_3DBC/$RCM/hist/$VAR/ $landmask
 fi
 
  ##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/hist/$VAR/
 
  #RCP2.6
  #calc_indices $filedir_3DBC_rcp26/$RCM/$VAR/hist/
  ##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp26/$VAR/
 
  # RCP4.5
  #calc_indices $filedir_3DBC_rcp45/$RCM/$VAR/hist/
  ##calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp45/$VAR/
 
done

# Fortsett her.
# Før denne kan fullføres: legg inn årstall i input til mergetime. Legg den inn etter kallet til calc_index over; hist tar bare 91-2020 osv.
#years=$(seq $startyear $endyear) 

#for y in $years; do
# cdo mergetime ./$RCM/tasmax/$ofile_tasmax_monmean   ./$RCM'/mergetime_tasmax_'$startyear'-'$endyear'.nc4'
# cdo mergetime ./$RCM/norheatwave/$ofile_norheatwave ./$RCM'/mergetime_norheatwave_'$startyear'-'$endyear'.nc4'

# cdo ifthen $landmask -monmean ./$RCM/'/mergetime_norheatwave_'$startyear'-'$endyear'.nc4'     ./$RCM'/land_tasmax'
# cdo ifthen $landmask -monmean ./$RCM/'/mergetime_norheatwave_'$startyear'-'$endyear'.nc4'     ./$RCM'/land_norheatwave'
 
#done

#return to starting dir
cd $PWD




echo -ne "\n=====\nDone!\n"
