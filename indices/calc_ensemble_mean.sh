#!/bin/bash
# Written by IBNI 2022-01-09. Last edited by IBNI 2022-01-27.
# Models to process (from CMIP5, bias-adjusted with two BC methods):
# 1 ecearth-r12i1p1-cclm
# 2 ecearth-r3i1p1-hirham
# 3 noresm-r1i1p1-remo
# 4 mpi-r2i1p1-remo
# 5 mpi-r1i1p1-cclm
# 6 cnrm-r1i1p1-aladin
# 7 noresm-r1i1p1-rca
# 8 hadgem-r1i1p1-rca
# 9 hadgem-r1i1p1-remo
#10 ecearth-r12i1p1-rca
#
# Call to make before running this script:
# /hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/temperature_indices_TAS.sh mpi-r2i1p1-remo  1
## ...Either process each model individually... or use the loop in line 50.
##./temperature_indices_TAS.sh  ecearth-r12i1p1-rca 1
##./temperature_indices_TAS.sh  hadgem-r1i1p1-rca  1
##./temperature_indices_TAS.sh  hadgem-r1i1p1-remo 1
##./temperature_indices_TAS.sh  noresm-r1i1p1-rca  1
##./temperature_indices_TAS.sh  cnrm-r1i1p1-aladin 1
##./temperature_indices_TAS.sh  mpi-r1i1p1-cclm    1
##./temperature_indices_TAS.sh  mpi-r2i1p1-remo    1
##./temperature_indices_TAS.sh  noresm-r1i1p1-remo 1
##./temperature_indices_TAS.sh  ecearth-r3i1p1-hirham 1 
##./temperature_indices_TAS.sh  ecearth-r12i1p1-cclm 1

# Call to run this script:
# Run from savedir = /hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/$bcm/ensemble/
# First time, you need to compute the common ensemble mean by setting yearStart to 1991.
# /hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/calc_ensemble_mean.sh 'tas' 1991 rcp45 3dbc d
# ...for each variable and percentile separately.
#
#/hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/calc_ensemble_mean.sh 'tas' 2071 rcp45 eqm d
#/hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/calc_ensemble_mean.sh 'tas_DJF' 2071 rcp45 eq d
#/hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/calc_ensemble_mean.sh 'tetraterm' 2071 rcp45 eqm d
#/hdata/hmdata/KiN2100/analyses/github/KiN2100/indices/calc_ensemble_mean.sh 'cdd' 2071 rcp45 eqm d


set -e # stops the script if there is an error message.
echo ''
echo 'This script takes 5 arguments: variable (tas, tas_MAM, tetraterm etc), yearStart (2041 or 2071), rcp (rcp45), bias-correction method (3dbc or eqm),  and whether the deviation from reference shall be calculated as a difference (d) or percentage change (c).'
echo ''

model=('mpi-r1i1p1-cclm' 'mpi-r2i1p1-remo' 'hadgem-r1i1p1-remo' 'noresm-r1i1p1-rca' 'hadgem-r1i1p1-rca' 'ecearth-r12i1p1-rca' 'cnrm-r1i1p1-aladin' 'noresm-r1i1p1-remo' 'ecearth-r12i1p1-cclm' 'ecearth-r3i1p1-hirham') #echo ${model[0]} # print the first element

# Process all temperature indices first, if it is not already done:

#for m in $(seq 1 10); do
#    ./temperature_indices_TAS.sh $filedir/${model[$i-1]} 1  # Note! Bash starts counting at 0 ($i-1).
#done


var=$1  # 'tetraterm'
yearStart=$2
rcp=$3 
yearEnd=$(( $yearStart + 29 ))
# a=`expr "$a" + "$num"`
# a=$(($a+$num))   # fikk ikke denne summen til å funke :(
#yearEnd=$(($yearStart+$interval))
#yearEnd=`expr "$yearStart" + "$interval"`
#let yearEnd=$yearStart+$interval
bcmethod=$4   # 'eqm_projections'    # '3dbc_projections'
deviation=$5  # 'd' for difference, 'c' for percentage change 



    # Filnavn fra input:
    #cnrm-r1i1p1-aladin_rcp45_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_2015.nc4

if [ $bcmethod = '3dbc' ]; then
     bcm='3dbc_projections'
     # Hva var tanken med å legge inn alle variable her? Å automatisk skille "d" fra "c"?
     # Det betyr at man manuelt må legge inn nye variable her.
     #if [ $var = 'tas' ] || [ $var = 'tas_MAM' ] || [ $var = 'tas_JJA' ] || [ $var = 'tas_SON' ] || [ $var = 'tas_DJF' ] || [ $var = 'gdd' ] || [ $var = 'hdd' ] || [ $var = 'cdd' ] || [ $var = 'tetraterm' ] || [ $var = 'gsl' ]; then
          biasbaseline='3dbc-sn2018v2005_rawbc_norway_1km'
     #fi
elif [ $bcmethod = 'eqm' ]; then
       bcm='eqm_projections'
     #if [ $var = 'tas' ] || [ $var = 'tas_MAM' ] || [ $var = 'tas_JJA' ] || [ $var = 'tas_SON' ] || [ $var = 'tas_DJF' ] || [ $var = 'gdd' ] || [ $var = 'hdd' ] || [ $var = 'cdd' ] || [ $var = 'tetraterm' ] || [ $var = 'gsl' ]; then
	 biasbaseline='eqm-sn2018v2005_rawbc_norway_1km'  
     #fi
fi


echo 'RCP = ' $rcp
echo 'End year = '$yearEnd



# Delete this, it is only needed when origdir is being used.
#if [ $bcm = '3dbc_projections' ]; then
#    bcmdir='3dbc-eqm'
#elif [ $bcm = 'eqm_projections' ]; then
#    bcmdir='eqm'
#else
#    echo "Please check your argument bcm (bias-correction method) and file paths of filedir and savedir."
#fi


# Specify directories
#origdir='/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/'$bcmdir'/netcdf/'
filedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/'$bcm'/'
savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/'$bcm'/ensemble'



# Calculate a common ensemble of all models for the historical period by looping over all models
# (need  to do this only once)

if [ $yearStart = '1991' ]; then   # choose 1991 first to compute a common ensemble mean

     echo $yearStart
     ls $filedir/*/$var'_30-yrmean_mgtim_1991-2020.nc'
#     ls $filedir/*/$var'_30-yrmean_mgtim_2071-2100.nc'
     echo 'I will now spend some time computing ensmean and enspctls.'
     
     cdo ensmean  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_mean_1991-2020_'$var'.nc'

     # Compute and display values for mainland Norway, save these.
     # cdo fldmean $savedir/'common_ensemble_mean_1991-2020_'$var'.nc' $savedir/'fldmean_'$devi'_1991-2020.nc'
     #                               endre mean til ensmean? Må gjøres konsistent.
     cdo fldmean $savedir/'common_ensemble_mean_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_ensmean_'$var'.nc'


     echo 
     echo 'Printing fieldmean of ensmean for 1991-2020:'
     echo 
   
     cdo info $savedir/'fldmean_1991-2020_ensmean_'$var'.nc'

     for pctls in 10 25 50 75 90; do
        cdo enspctl,$pctls  $filedir/*/$var*_30-yrmean_mgtim_1991-2020.nc $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc'
     
        cdo fldmean $savedir/'common_ensemble_enspctl-'$pctls'_1991-2020_'$var'.nc' $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'
     
        echo 
        echo 'Printing fieldmean for 1991-2020, enspctl=' $enspctl
        echo 
     
        cdo info $savedir/'fldmean_1991-2020_enspctl-'$pctls'.nc'

    done   # Done looping over percentiles: 10,25,50,75,90
     
else
   
    echo 'Startyear = ' $yearStart

 
   for i in $(seq 0 9); do         # Loop over models  # Note! Bash starts counting at 0.

       # echo $filedir/${model[$i]}/$var*_30-yrmean_mgtim_timmean_2071-2100.nc
       #                      /tetraterm_30-yrmean_mgtim_timmean_2071-2100.nc

       cd $filedir/${model[$i]}
       # pwd
       echo ''
       #ls $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc'   #2071-2100.nc'
       #ls $filedir/${model[$i]}/$var'_30-yrmean_mgtim_1991-2020.nc'    

       if [ $deviation = 'd' ]; then
	   devi='d'$var
	   echo 'Computing differences by subtracting the reference period. Name:' $devi

           ## Subtract the reference period from the individual model.
	   # Then multiply with the landmask to get rid of cells outside of Norway.
	   cdo mul -sub   $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc' $filedir/${model[$i]}/$var'_30-yrmean_mgtim_1991-2020.nc' '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc'	   # Meaning that I have subtracted the reference period from each single model

# OLD	   cdo mul -sub   $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc' $filedir/${model[$i]}/$var'_30-yrmean_mgtim_1991-2020.nc' '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc'	   
#           $filedir/${model[$i]}/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc'

	   # -> cdo mul hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4 -sub tas_2071-2100.nc tas_1991-2020.nc outfile.nc
    
	   ## Also, subtract a common reference period for the ensemble of models (1991-2020)
	   cdo  mul  -sub   $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc' $savedir/'common_ensemble_mean_1991-2020_'$var'.nc' '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'

# old:	   cdo  mul  -sub   $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc' $savedir/'common_ensemble_mean_1991-2020_'$var'.nc' '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'	   

	   # Filnavn fra input:
	   #cnrm-r1i1p1-aladin_rcp45_eqm-sn2018v2005_rawbc_norway_1km_tas_daily_2015.nc4

       elif [ $deviation = 'c' ]; then

	   if [[ $var == tas* ]] || [ $var == 'tetraterm' ] || [ $var == 'hdd' ] || [ $var == 'cdd' ] || [ $var == 'gdd' ] ; then
	       # Note the double brackets and star in tas*:
	       # https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value
              echo 'Are you sure you want to compute the percentage change from variable ' $var '? I dont think so.'
	      exit 1    # stops the program.
	   fi
	      
	   devi='c'$var
	   echo $devi

           ## This can be omitted because the common ensemble is almost identical to the ensemble:
	   ## Compute percentage change for individual models.
           # Then multiply with the landmask to get rid of cells outside of Norway.
           cdo mulc,100 -mul -div -sub   $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc' $filedir/${model[$i]}/$var'_30-yrmean_mgtim_1991-2020.nc' $filedir/${model[$i]}/$var'_30-yrmean_mgtim_1991-2020.nc' '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc'

   
           ## common reference period for the ensemble of models (1991-2020)
           
	   cdo  mulc,100 -mul -div -sub  $filedir/${model[$i]}/$var'_30-yrmean_mgtim_'$yearStart'-'$yearEnd'.nc'    $savedir/'common_ensemble_mean_1991-2020_'$var'.nc'    $savedir/'common_ensemble_mean_1991-2020_'$var'.nc'    '/hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4' $filedir/${model[$i]}/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'
                                              
    
       fi  # end if deviation=d (difference) or c (change)

    ## Delete this:    
    ##  'cdo -b 32 sub mean_'$rcp'_crossings_2031-2060.nc mean_hist_crossings_71-00.nc diff_'$rcp'_2031-2060.nc'
    # # 'cdo -b 32 sub mean_'$rcp'_crossings_'$yearStart'-'$yearEnd'.nc mean_hist_crossings_71-00.nc diff_'$rcp'_'$yearStart'-'$yearEnd'.nc'
    #  
    ## cdo gec,0 diff_$rcp'_2031-2060.nc' 'pos_'$rcp'_2031-2060.nc'
    ## cdo gec,0 diff_$rcp'_'$yearStart'-'$yearEnd'.nc' 'pos_'$rcp'_'$yearStart'-'$yearEnd'.nc'
   done

   # Calculate ensemble mean of the index (NB! Some indices might require sums, such as Days with zero-crossings, DZCs.)

   echo 'calculate ensmean of all models by subtracting the reference period from EACH MODEL separately'

    cdo ensmean $filedir/'cnrm-r1i1p1-aladin'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'ecearth-r12i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'ecearth-r12i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'ecearth-r3i1p1-hirham'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'hadgem-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'hadgem-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'mpi-r1i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'mpi-r2i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'noresm-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $filedir/'noresm-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc' $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_ensmean.nc'

    cdo fldmean $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_ensmean.nc' $savedir/'fldmean_'$devi'_'$rcp'_'$yearStart'-'$yearEnd'_each_model.nc'
    
    echo 
    echo 'Printing fieldmean for projected difference, subtracting the reference for each model.'
    echo 
    cdo info $savedir/'fldmean_'$devi'_'$rcp'_'$yearStart'-'$yearEnd'_each_model.nc'
    
# OLD      cdo ensmean $filedir/'cnrm-r1i1p1-aladin'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc'  $filedir/'ecearth-r12i1p1-cclm'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'ecearth-r12i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'ecearth-r3i1p1-hirham'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'hadgem-r1i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'hadgem-r1i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'mpi-r1i1p1-cclm'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'mpi-r2i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'noresm-r1i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'noresm-r1i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020.nc'

    # LURER pÅ OM DENNE IKKE TRENGS?
#    for pctls in 10 25 50 75 90; do
#        cdo enspctl,$pctls $filedir/'cnrm-r1i1p1-aladin'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc'  $filedir/'ecearth-r12i1p1-cclm'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'ecearth-r12i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'ecearth-r3i1p1-hirham'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'hadgem-r1i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'hadgem-r1i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'mpi-r1i1p1-cclm'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'mpi-r2i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'noresm-r1i1p1-rca'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $filedir/'noresm-r1i1p1-remo'/$var'_diff_30-yrmean_'$yearStart'-'$yearEnd'_1991-2020_'$rcp'.nc' $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_enspctl-'$pctls'.nc'

#   done # Done looping over percentiles 10,25,50,75,90
   
### Trenger ikke denne, for landmaska er haandtert over.
###cdo mul ensemble_rcp45_3dbc-sn2018v2005_rawbc_norway_1km_ctetraterm_annual-mean_2071-2100_1991-2020_common_ensemble.nc /hdata/hmdata/KiN2100/analyses/kss2023_mask1km_norway.nc4 ensemble_rcp45_3dbc-sn2018v2005_rawbc_nor_1km_ctetraterm_annual-mean_2071-2100_1991-2020.nc4


   if [ $deviation = 'd' ]; then 
   # Ensemble computed by subtracting a common ensemble for the reference period.


    for pctls in 10 25 50 75 90; do

       echo 'calculate ensemble PERCENTILES of all models by subtracting the reference period from a COMMON ENSEMBLE. Percentile=' $pctls

       cdo enspctl,$pctls  $filedir/'cnrm-r1i1p1-aladin'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'  $filedir/'ecearth-r12i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'ecearth-r12i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'ecearth-r3i1p1-hirham'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'hadgem-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'hadgem-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'mpi-r1i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'mpi-r2i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'noresm-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'noresm-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'  $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble_enspctl_'$pctls'.nc'

        echo 
        echo 'Printing fieldmean for projected difference, percentile =' $pctls 
        echo 
        cdo fldmean $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble_enspctl_'$pctls'.nc' $savedir/'fldmean_'$devi'_'$rcp'_'$yearStart'-'$yearEnd'_common_ensemble_enspctl_'$pctls'.nc'  
    
        cdo info $savedir/'fldmean_'$devi'_'$rcp'_'$yearStart'-'$yearEnd'_common_ensemble_enspctl_'$pctls'.nc'
	
   done # Done looping over percentiles 10,25,50,75,90

       echo 'calculate ensMEAN of all models by subtracting the reference period from a COMMON ENSEMBLE'
	   
   # MAKE enspctl versions for devi=c  above  
       
   cdo ensmean  $filedir/'cnrm-r1i1p1-aladin'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'  $filedir/'ecearth-r12i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'ecearth-r12i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'ecearth-r3i1p1-hirham'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'hadgem-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'hadgem-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'mpi-r1i1p1-cclm'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'mpi-r2i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'noresm-r1i1p1-rca'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc' $filedir/'noresm-r1i1p1-remo'/$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble.nc'  $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble_ensmean.nc'  
   fi   # end IF deviation = 'd'

   # Compute and display the mean value of mainland Norway, for the projection period only:
   
   echo 
   echo 'Printing fieldmean for projected change or difference, ensMEAN:'
   echo 

   
   cdo fldmean $savedir/'ensemble_'$rcp'_'$biasbaseline'_'$devi'_annual-mean_'$yearStart'-'$yearEnd'_1991-2020_common_ensemble_ensmean.nc' $savedir/'fldmean_'$rcp'_'$devi'_'$yearStart'-'$yearEnd'_common_ensemble_ensmean.nc'  
   
   cdo info $savedir/'fldmean_'$rcp'_'$devi'_'$yearStart'-'$yearEnd'_common_ensemble_ensmean.nc'  

   
   # Erfaring: med og uten common_ensemble gir identisk ensemblemean (fieldmean) til nærmeste 4. desimal...
   
# old script with ensemble median and models from KiN-2015
# cdo enspctl,50 $filedir/'CNRM_CCLM'/'diff_'$rcp'_2031-2060.nc' $filedir/'CNRM_RCA'/'diff_'$rcp'_2031-2060.nc' $filedir/'EC-EARTH_CCLM'/'diff_'$rcp'_2031-2060.nc' $filedir/'EC-EARTH_HIRHAM'/'diff_'$rcp'_2031-2060.nc' $filedir/'EC-EARTH_RACMO'/'diff_'$rcp'_2031-2060.nc' $filedir/'EC-EARTH_RCA'/'diff_'$rcp'_2031-2060.nc' $filedir/'HADGEM_RCA'/'diff_'$rcp'_2031-2060.nc' $filedir/'IPSL_RCA'/'diff_'$rcp'_2031-2060.nc' $filedir/'MPI_CCLM'/'diff_'$rcp'_2031-2060.nc' $filedir/'MPI_RCA'/'diff_'$rcp'_2031-2060.nc' $filedir/ensemble_diff-crossings_pctl_50_$rcp'_2031-2060.nc'

fi # end if yearStart=1991, that is, to compute a common ensemble mean


rm $savedir/'ensemble_'$rcp*$devi*'.nc'
