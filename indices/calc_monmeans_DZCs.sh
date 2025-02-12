#!/usr/bin/bash
set -e #exit on error

## Script to calculate monthly mean DZC (days with 0 deg. crossings) of the bias-adjusted RCM data
#
# EQM and 3DBC
# Hist, rcp26 and rcp45
#
# Call: ./calc_monmeans_DZCs.sh

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

### Main script
#Save current dir for return point
currdir=$PWD

#go to working dir
workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc
cd $workdir

#get list of RCMs
RCMLIST=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/ | grep -v CMIP`
echo "Found the following RCMs:"
echo $RCMLIST | tr " " "\n"
echo -ne "======================"

for RCM in $RCMLIST
do
 ### EQM
 echo -ne "\n\nProcessing" $RCM "EQM \n"
 mkdir -p $RCM/dzc
 
 #HIST
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/tasmax/hist/*`
 nbrfiles=`echo $filelist | wc -w`
 echo "Hist: Processing" $nbrfiles "files"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done
 
 #RCP2.6
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/tasmax/rcp26/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP2.6: Processing" $nbrfiles "files\n"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP4.5
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/tasmax/rcp45/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP4.5: Processing" $nbrfiles "files\n"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 ### 3DBC
 echo -ne "\n\nProcessing" $RCM "3DBC \n"

 #HIST
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/tasmax/hist/*`
 nbrfiles=`echo $filelist | wc -w`
 echo "Hist: Processing" $nbrfiles "files"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP2.6
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/tasmax/rcp26/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP2.6: Processing" $nbrfiles "files\n"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP4.5
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/tasmax/rcp45/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP4.5: Processing" $nbrfiles "files\n"
 for file in $filelist
 do tasminfile=`echo $file | sed s/tasmax/tasmin/g`
  ofile=`basename $file | sed s/daily/monthly/ | sed s/tasmax/dzc/g`
  cdo -L -s chname,tasmin,dzc -monsum -mul -ltc,273.15  $tasminfile -gtc,273.15  $file $RCM/dzc/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

done


#return to starting dir
cd $PWD


echo -ne "\n=====\nDone!\n"
