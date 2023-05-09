#!/usr/bin/bash
set -e #exit on error

## Script to calculate monthly means of the bias-adjusted RCM data
#
# EQM and 3DBC
# Hist, rcp26 and rcp45 so far, ssp3.70 to follow
#
# Call: ./calc_monmeans.sh VAR
# where VAR is one of hurs, pr, ps, rlds, rsds, sfcWind, tas, tasmax, tasmin

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

#Check provision of varname
if [ -z "$1" ]; then
 echo "no variable specified!"
 exit 1
fi

VAR=$1

#go to working dir
workdir=/lustre/storeC-ext/users/kin2100/MET/monmeans_bc
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
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/hist/*`
 nbrfiles=`echo $filelist | wc -w`
 echo "Hist: Processing" $nbrfiles "files"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP2.6
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp26/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP2.6: Processing" $nbrfiles "files\n"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP4.5
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/NVE/EQM/$RCM/$VAR/rcp45/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP4.5: Processing" $nbrfiles "files\n"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 ### 3DBC
 echo -ne "\n\nProcessing" $RCM "3DBC" $VAR "\n"

 #HIST
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/hist/$VAR/*`
 nbrfiles=`echo $filelist | wc -w`
 echo "Hist: Processing" $nbrfiles "files"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP2.6
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp26/$VAR/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP2.6: Processing" $nbrfiles "files\n"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

 #RCP4.5
 count=0
 filelist=`ls /lustre/storeC-ext/users/kin2100/MET/3DBC/application/$RCM/rcp45/$VAR/*`
 nbrfiles=`echo $filelist | wc -w`
 echo -ne "\nRCP4.5: Processing" $nbrfiles "files\n"
 for file in $filelist
 do ofile=`basename $file | sed s/daily/monthly/`
  cdo -s monmean $file $RCM/$VAR/$ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done

done


#return to starting dir
cd $PWD


echo -ne "\n=====\nDone!\n"
