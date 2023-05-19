#!/usr/bin/bash
set -e #exit on error

## Script to calculate monthly means of the bias-adjusted RCM data
#
# EQM and 3DBC
# Hist, rcp26 and rcp45 so far, ssp3.70 to follow
#
# Call: ./calc_generalised_indices.sh VAR
# where VAR is one of hurs, pr, ps, rlds, rsds, sfcWind, tas, tasmax, tasmin
#
# Run from workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc


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


function calc_indices {       # one input argument:  filedir
   # på formen /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/$1/*`
   count=0
   filelist=`ls $1`
   nbrfiles=`echo $filelist | wc -w`
   echo "Processing " $1
   echo "Processing " $nbrfiles " files"
   for file in $filelist
      do ofile=`basename $file | sed s/daily/monthly/`
      cdo -s monmean $file $RCM/$VAR/$ofile
      if [ $VAR == "pr" ]; then
         echo "pr chosen"
     
	 # ncatted
	 
      elif [ $VAR == "tas" ]; then 
         echo "tas chosen"
	 ofile_gsl=`echo $ofile | sed s/tas/gsl/`

	# vekstsesongens lengde
        cdo eca_gsl $ifile landmask -gec,20 $ifile $RCM/$VAR/$ofile_VAR
	
	
      elif [ $VAR == "tasmax" ]; then 
         echo "tasmax chosen"

	 # tropenattdøgn
	 ofile_tropnight=`echo $ofile | sed s/tasmax/tropnight/`
         mkdir -p $RCM/tropnight/
         cdo monsum -gec,20 $ifile $RCM/tropnight/$ofile_tropnight

	 # ncatted

 	 # Nullgradspasseringer
##        echo "dzc chosen"
##	    filelist_tasmin=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/TASMIN/hist/*`
##	    nbrfiles=`echo $filelist | wc -w`
	 
	ifileX = $ifile
	ifileN = `echo $ifile | sed s/tasmax/tasmin/`

	ofile_dzc=`echo $ofile | sed s/tasmax/dzc/`
	mkdir -p  $RCM/dzc/
	cdo monsum -mul -ltc,0 $ifileN -gtc,0 $ifileX $RCM/dzc/$ofile_dzc

	# ncatted

	# DTR		
	ofile_dtr=`echo $ofile | sed s/tasmax/dtr/`
	mkdir -p  $RCM/dtr/
	cdo sub $ifileX $ifileN $RCM/$dzc/$ofile_dtr
	
        # ncatted
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



VAR=$1      # note: not to be confused with $1 in the functions



#go to working dir
workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc/test_ibni
cd $workdir

#get list of RCMs
RCMLIST=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/`
echo "Found the following RCMs:"
echo $RCMLIST | tr " " "\n"
echo -ne "======================"

for RCM in $RCMLIST
do
 ### EQM
 echo -ne "\n\nProcessing" $RCM "EQM" $VAR "\n"
 mkdir -p $RCM/$VAR
 
 #HIST
 # calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/hist/

 #RCP2.6
 # calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp26/

 #RCP4.5
 # calc_indices /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp45/
 
 ### 3DBC
 echo -ne "\n\nProcessing" $RCM "3DBC" $VAR "\n"

 #HIST
 calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/hist/$VAR/
 
 #RCP2.6
 # calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp26/$VAR/
 
 # RCP4.5
 # calc_indices /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp45/$VAR/
 
done


#return to starting dir
cd $PWD




echo -ne "\n=====\nDone!\n"
