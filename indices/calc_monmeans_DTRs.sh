#!/usr/bin/bash
set -e #exit on error

## Script to calculate monthly mean DTR (daily temperature range) of the bias-adjusted RCM data
# Note: monmean(DTR) = monmean(tasmax_daily-tasmin_daily) = monmean(tasmax) - monmean(tasmin), i.e.
# it can be calculated from monthly tasmax and tasmin date
#
# EQM and 3DBC
# Hist, rcp26 and rcp45
#
# Call: ./calc_monmeans_DTRs.sh

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
RCMLIST=`ls`
echo "Found the following RCMs:"
echo $RCMLIST | tr " " "\n"
echo -ne "======================"

for RCM in $RCMLIST
do
 ### All sims
 echo -ne "\n\nProcessing" $RCM "\n"
 mkdir -p $RCM/dtr
 
 count=0
 filelist=`ls $RCM/tasmax/*`
 nbrfiles=`echo $filelist | wc -w`
 echo "Processing" $nbrfiles "files"
 for file in $filelist
 do tnfile=`echo $file | sed s/tasmax/tasmin/g`
    ofile=`echo $file | sed s/tasmax/dtr/g`
  cdo -z zip_1 -s expr,"dtr=tasmax-tasmin;" -merge $file $tnfile $ofile
  ncatted -h -a standard_name,dtr,o,c,"diurnal_temperature_range" -a long_name,dtr,o,c,"Diurnal temperature range" -a units,dtr,o,c,"K" $ofile
  ((count+=1))
  ProgressBar $count $nbrfiles && : #update progress bar and set to OK to skip exiting the script
 done
 
done

#return to starting dir
cd $PWD


echo -ne "\n=====\nDone!\n"
