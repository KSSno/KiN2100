#!/bin/bash


# CALL: ../temperature_indices_Tasmax-Tasmin_senorge-hist.sh 1 1961 
# (0 if you want to skip processing (meaning it starts after mergetime), otherwise 1)
# Remember to log into a screen terminal before running.
# 
# ibni@ppi-ext-login.met.no:/lustre/storeC-ext/users/kin2100/NVE/analyses/temperature_inds/
# Last edited by IBNI 9-03-2023.

# This script computes:
# hetebølgeindeks (hdwi-nor)
# gjennomsnitt av TAX (tasmax) annual, seasonal
# gjennomsnitt av TAN (tasmin) annual, seasonal
# DTR (dtr) annual, seasonal
# nullgraderspasseringer (dzc) annual, seasonal
# nordiske sommerdager >20 (summerd_nor)
# tropenetter (tropnight)
# frostnetter (fd)

set -e # denne stopper scriptet hvis det kommer en feilmelding.

startyear=$2

echo "This program calculates temperature indicators from TmaxTmin (heatwave index, zero-degree crossings). This progam takes one argument."
# Double check that years cover the intended period!"# and months cover 1 12
echo "Argument 1 = 0 if you want to skip the processing, else 1. Now it is = " $1


# filedir='/lustre/storeA/project/metkl/senorge2/archive/seNorge_2018_v20_05' # På lustre
filedir='/hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf/' #NVE

# savedir='/lustre/storeC-ext/users/kin2100/NVE/analyses/indicators/temperature_inds'
# savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/senorge/months' #NVE
# savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/senorge/seasonal61-90/' #NVE

if [ $startyear = "1961" ]; then
    endyear=1990
    echo "Startyear = " $startyear ". Double-check your endyear = " $endyear
    savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/senorge/seasonal61-90/' #NVE
elif [ $startyear = "1991" ]; then
    endyear=2020
    echo "Startyear = " $startyear ". Double-check your endyear = " $endyear
    savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/senorge/seasonal91-20/' #NVE
else
    echo "Double-check your chosen startyear = " $startyear
fi




################
## Loop over each year and calculate indices per year
################

  years=$(seq $startyear $endyear)             # $(seq 1990 2020)



  
  for y in $years; do
      #   echo $years

    if [ $1 = "1" ]; then          # Continue to reading in files and processing indices only if argument 1 = 1. Otherwise, skip processing.

      
    #ifileG=$filedir'/tg_senorge2018_'$y'.nc' # Tmean,  daily mean temperature
     ifileX=$filedir'/tx_senorge2018_'$y'.nc'  # Tmax,  daily max temperature
     ifileN=$filedir'/tn_senorge2018_'$y'.nc'  # Tmin,  daily min temperature
     echo $ifileX
     echo $ifileN
     #    echo "Done reading in temperature variables for year" $y
     
     # Here, you may add one single, or a few, indices that you want to process.
     ## cdo timsum -mul -ltc,0 $ifileN -gtc,0 $ifileX  $savedir'/'$y'_zerodeg_ANN.nc'
     # In that case, remember to add the corresponding line of mergetime further down,
     # otherwise the script will stop prematurely and you will have to type this in the terminal:. 
     # cdo mergetime *_zerodeg_ANN.nc mergetime_zerodeg_ANN.nc
     
#    # Note that these fields have been extracted from original seNorge files.  
#    # cdo selvar,'tx' $ynfile $savedir'/SeNorge2018/tx_'$y'.nc' # maximum temperature
#    # cdo selvar,'tn' $ynfile $savedir'/SeNorge2018/tn_'$y'.nc' # minimum temperature
#    # First time, this gave the following error on fillValues: (solution here: https://github.com/metno/seNorge_docs/issues/3)
#    # Error (cdf_put_att_double): NetCDF: Not a valid data type or _FillValue type mismatch


     ################
     # Compute indices 
     ################
     
     ## Heatwave index

     # Fra 1. juni 2022 er indeksen med glidende middel av maksimumstemperatur ≥ 28 °C og minimumstemperatur ≥ 16 °C over 5 dager den offisielle hetebølge definisjonen for Norge, og blir kalt 'Norsk hetebølge'. 
     ## Running mean of Tmax over 5 days (for the heatwave index)

     #cdo gec,28 $savedir'/runmean5_Tmax_'$y'.nc' $savedir'/gec28_runmean5_Tmax_'$y'.nc' 
     #cdo gec,16 $savedir'/runmean3_Tmin_'$y'.nc' $savedir'/gec16_runmean3_Tmin_'$y'.nc'

     cdo yearsum -mul -gec,28 -runmean,5 $ifileX -gec,16 -runmean,5 $ifileN  $savedir'/'$y'_hdwi-nor.nc'        # cdo timsum er identisk med cdo yearsum her! Summerer alle dager i et år.
     # sesong trengs ikke for hetebølge!

     #     cdo yearsum -mul -gec,28 -runmean,3 $ifileX -gec,16 -runmean,3 $ifileN  $savedir'/'$y'_heatwave_index28X-16N-3days.nc'
     #     cdo yearsum -gec,28 -runmean,3 $ifileX $savedir'/'$y'_heatwave_index28X-3days.nc' 
     
     # cdo yearsum -mul -gec,28 -runmean,5  /hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf/tx_senorge2018_1991.nc  -gec,16 -runmean,5 /hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf/tn_senorge2018_1991.nc  ./1991_hdwi-nor.nc
     

      ## DTR, diurnal temperature range

      #     # pipe: cdo timmean -sub -selmon,1 ../../tx_senorge2018_1957.nc -selmon,1 ../../tn_senorge2018_1957.nc 1957_1_DTRPIP.nc


      cdo timmean -sub -selmon,12,1,2 $ifileX -selmon,12,1,2 $ifileN $savedir'/'$y'_DTR_DJF.nc'
      cdo timmean -sub -selmon,3/5    $ifileX -selmon,3/5    $ifileN $savedir'/'$y'_DTR_MAM.nc'
      cdo timmean -sub -selmon,6/8    $ifileX -selmon,6/8    $ifileN $savedir'/'$y'_DTR_JJA.nc'
      cdo timmean -sub -selmon,9/11   $ifileX -selmon,9/11   $ifileN $savedir'/'$y'_DTR_SON.nc'

      cdo timmean -sub $ifileX $ifileN  $savedir'/'$y'_DTR_ANN.nc'  #-abs er fjernet

      ## Frost days      # TRENGS ikke for sesong!
      # pipe:cdo timsum -ltc,0 -selmon,1 ../../tn_senorge2018_1957.nc 1957_1_frostnumberPIP.nc

      cdo timsum -ltc,0 $ifileN  $savedir'/'$y'_fd.nc' #frost_days.nc'


      ## Tropnightdøgn

      cdo timsum -gec,20 $ifileN  $savedir'/'$y'_tropnight.nc'
      #      cdo timsum -gec,20 -selmon,$mon $ifileN $savedir'/'$y'_'$mon'_tropnight_days_monthly.nc'
     
      ## Sommerger
      ## Her brukes 20 grader for å beregne nordiske sommerdøgn, ikke 25. Fra Helga: .. Vi har brukt TAX>=25 som er sommerdager. Men det er vanligere at vi bruker nordiske sommerdager (typisk i media) og det er TAX>=20'C. 

       cdo timsum -gec,20 $ifileX  $savedir'/'$y'_summerd-nor.nc'
      # cdo timsum -gec,20 -selmon,$mon $ifileX $savedir'/'$y'_'$mon'_sommerdag_days_monthly.nc'

     ## Gjennomsnitt av TAX og TAN
     
      cdo timmean $ifileX  $savedir'/'$y'_TAX_timmean_ANN.nc'
      cdo timmean $ifileN  $savedir'/'$y'_TAN_timmean_ANN.nc'
    
      cdo timmean  -selmon,12,1,2 $ifileX $savedir'/'$y'_TAX_timmean_DJF.nc'
      cdo timmean  -selmon,3/5    $ifileX $savedir'/'$y'_TAX_timmean_MAM.nc'
      cdo timmean  -selmon,6/8    $ifileX $savedir'/'$y'_TAX_timmean_JJA.nc'
      cdo timmean  -selmon,9/11   $ifileX $savedir'/'$y'_TAX_timmean_SON.nc'

      cdo timmean  -selmon,12,1,2 $ifileN $savedir'/'$y'_TAN_timmean_DJF.nc'
      cdo timmean  -selmon,3/5    $ifileN $savedir'/'$y'_TAN_timmean_MAM.nc'
      cdo timmean  -selmon,6/8    $ifileN $savedir'/'$y'_TAN_timmean_JJA.nc'
      cdo timmean  -selmon,9/11   $ifileN $savedir'/'$y'_TAN_timmean_SON.nc'
     
      ## Zero-degree crossings
      #     # pipe: cdo timsum -mul -ltc,0 -selmon,1 ../../tn_senorge2018_1957.nc -gtc,0 -selmon,1 ../../tx_senorge2018_1957.nc 1957_1_crossingnumberPIP.nc
      #  cdo timsum -mul -ltc,0 -selmon,$mon $ifileN -gtc,0 -selmon,$mon $ifileX $savedir'/'$y'_'$mon'_'zero-crossings_days_monthly.nc'

      cdo timsum -mul -ltc,0 -selmon,12,1,2 $ifileN -gtc,0 -selmon,12,1,2 $ifileX $savedir'/'$y'_zerodeg_DJF.nc'
      cdo timsum -mul -ltc,0 -selmon,3/5 $ifileN    -gtc,0 -selmon,3/5 $ifileX $savedir'/'$y'_zerodeg_MAM.nc'
      cdo timsum -mul -ltc,0 -selmon,6/8 $ifileN    -gtc,0 -selmon,6/8 $ifileX $savedir'/'$y'_zerodeg_JJA.nc'
      cdo timsum -mul -ltc,0 -selmon,9/11 $ifileN   -gtc,0 -selmon,9/11 $ifileX $savedir'/'$y'_zerodeg_SON.nc'
     
      cdo timsum -mul -ltc,0 $ifileN -gtc,0 $ifileX  $savedir'/'$y'_zerodeg_ANN.nc'
      # echo 'done calculating monthly sums of indices. Now combine into annual values.'

      fi      # end testing-if-sentencene  if[ $1 = "1" ]; then
              # The script reads in files and process indices only if argument 1 = 1. Otherwise, skip processing.
  done      # end for years


  if [ $1 = "1" ]; then          # Continue to reading in files and processing indices only if argument 1 = 1. Otherwise, skip processing.

  echo 'Done looping over years. The years processed were:' $years
      
  # # Then combine files into one large file with mergetime and calculate the sum for each year
  # # Ran these in the terminal (replacing "$savedir" with "." and "#" with "echo"):
  # # cdo mergetime *_zerodeg_ANN.nc mergetime_zerodeg_ANN.nc
  echo 'Now, copy the uncommented mergetime statements into the terminal if these lines fail:'

  cdo mergetime $savedir'/'*'_hdwi-nor.nc' $savedir'/mergetime_hdwi-nor_'$startyear'-'$endyear'.nc4'    # heatwave_index28X-16N-5days.nc'
  # cdo mergetime $savedir'/'*'_heatwave_index28X-16N-3days.nc' $savedir'/mergetime_heatwave_index28X-16N-3days.nc'
  # cdo mergetime $savedir'/'*'_heatwave_index28X-3days.nc' $savedir'/mer'$startyear'-'$endyeagetime_heatwave_index28X-3days.nc'
  cdo mergetime $savedir'/'*'_TAN_timmean_ANN.nc' $savedir'/mergetime_TAN_ANN_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAX_timmean_ANN.nc' $savedir'/mergetime_TAX_ANN_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAN_timmean_DJF.nc' $savedir'/mergetime_TAN_DJF_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAX_timmean_DJF.nc' $savedir'/mergetime_TAX_DJF_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAN_timmean_MAM.nc' $savedir'/mergetime_TAN_MAM_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAX_timmean_MAM.nc' $savedir'/mergetime_TAX_MAM_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAN_timmean_JJA.nc' $savedir'/mergetime_TAN_JJA_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAX_timmean_JJA.nc' $savedir'/mergetime_TAX_JJA_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAN_timmean_SON.nc' $savedir'/mergetime_TAN_SON_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_TAX_timmean_SON.nc' $savedir'/mergetime_TAX_SON_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_DTR_ANN.nc' $savedir'/mergetime_DTR_ANN_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_DTR_DJF.nc' $savedir'/mergetime_DTR_DJF_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_DTR_MAM.nc' $savedir'/mergetime_DTR_MAM_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_DTR_JJA.nc' $savedir'/mergetime_DTR_JJA_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_DTR_SON.nc' $savedir'/mergetime_DTR_SON_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_zerodeg_DJF.nc' $savedir'/mergetime_zerodeg_DJF_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_zerodeg_MAM.nc' $savedir'/mergetime_zerodeg_MAM_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_zerodeg_JJA.nc' $savedir'/mergetime_zerodeg_JJA_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_zerodeg_SON.nc' $savedir'/mergetime_zerodeg_SON_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_zerodeg_ANN.nc' $savedir'/mergetime_zerodeg_ANN_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_summerd-nor.nc' $savedir'/mergetime_summerd-nor_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_fd.nc' $savedir'/mergetime_fd_'$startyear'-'$endyear'.nc4'
  cdo mergetime $savedir'/'*'_tropnight.nc' $savedir'/mergetime_tropnight_'$startyear'-'$endyear'.nc4'

  echo 'Resist the urge to remove, but rather KEEP the mergetime files.' 
 fi      # end testing-if-sentencene  if[ $1 = "1" ]; then
 
 ################ 
 # USE /hdata/hmdata/KiN2100/analyses/github/KiN2100/geoinfo/NorwayMaskOnSeNorgeGrid.nc
 # or norgeDEM=/lustre/storeC-ext/users/kin2100/NVE/analyses/indicators/kss2023_dem1km_norway.nc4 # PPI
 # I originally used created a landmask from IHA's /app01-felles/iha/KiN2023/misc/kss2023_dem1km_norway.nc4 (this shows elevation, not just "1" for land cells)
 # IHA generated a landmask generated this way:
 # By masking all values greater than or equal to 0
 # cdo gec,0 /app01-felles/iha/KiN2023/misc/kss2023_dem1km_norway.nc4 kss2023_mask1km_norway.nc4
 #
 # NorwayMaskOnSeNorgeGrid.nc is generated this way:
 # By masking all positve values (which is equivalent):
 # cdo gtc,-Inf kss2023_dem1km_norway.nc4 NorwayMaskOnSeNorgeGrid.nc
 ################

  landMask=/hdata/hmdata/KiN2100/analyses/github/KiN2100/geoinfo/NorwayMaskOnSeNorgeGrid.nc

  echo "Crop the grid (containing Sweden and Finland) to mainland Norway only"
  echo 
  
  # And create 30-year means (-timmean on the mergetime files)
  cdo ifthen $landMask -timmean $savedir'/mergetime_hdwi-nor_'$startyear'-'$endyear'.nc4'     $savedir'/land_mrgtim_hdwi-nor'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAX_DJF_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAX_DJF.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAX_MAM_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAX_MAM.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAX_JJA_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAX_JJA.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAX_SON_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAX_SON.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAX_ANN_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAX_ANN.nc'

  cdo ifthen $landMask -timmean $savedir'/mergetime_TAN_DJF_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAN_DJF.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAN_MAM_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAN_MAM.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAN_JJA_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAN_JJA.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAN_SON_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAN_SON.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_TAN_ANN_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_TAN_ANN.nc'

  cdo ifthen $landMask -timmean $savedir'/mergetime_zerodeg_DJF_'$startyear'-'$endyear'.nc4'     $savedir'/land_mrgtim_zerodeg_DJF.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_zerodeg_MAM_'$startyear'-'$endyear'.nc4'     $savedir'/land_mrgtim_zerodeg_MAM.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_zerodeg_JJA_'$startyear'-'$endyear'.nc4'     $savedir'/land_mrgtim_zerodeg_JJA.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_zerodeg_SON_'$startyear'-'$endyear'.nc4'     $savedir'/land_mrgtim_zerodeg_SON.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_zerodeg_ANN_'$startyear'-'$endyear'.nc4'    $savedir'/land_mrgtim_zerodeg_ANN.nc'

  cdo ifthen $landMask -timmean $savedir'/mergetime_DTR_DJF_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_DTR_DJF.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_DTR_MAM_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_DTR_MAM.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_DTR_JJA_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_DTR_JJA.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_DTR_SON_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_DTR_SON.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_DTR_ANN_'$startyear'-'$endyear'.nc4'      $savedir'/land_mrgtim_DTR_ANN.nc'

  ##  cdo ifthen $landMask -timmean $savedir'/mergetime_heatwave_index28X-16N-5days_'$startyear'-'$endyear'.nc4'    $savedir'/land_mrgtim_hdwi-nor'
  ##  cdo ifthen $landMask -timmean $savedir'/mergetime_heatwave_index28X-16N-3days_'$startyear'-'$endyear'.nc4' $savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'
  #  cdo ifthen $landMask -timmean $savedir'/mergetime_heatwave_index28X-3days_'$startyear'-'$endyear'.nc4' $savedir'/land_mrgtim_heatwave_index28X-3days.nc'

  cdo ifthen $landMask -timmean $savedir'/mergetime_tropnight_'$startyear'-'$endyear'.nc4' $savedir'/land_mrgtim_tropnight.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_fd_'$startyear'-'$endyear'.nc4' $savedir'/land_mrgtim_fd.nc'
  cdo ifthen $landMask -timmean $savedir'/mergetime_summerd-nor_'$startyear'-'$endyear'.nc4' $savedir'/land_mrgtim_summerd-nor.nc'

 # I terminalen:
 # ln -s /hdata/hmdata/KiN2100/analyses/github/KiN2100/geoinfo/NorwayMaskOnSeNorgeGrid.nc landmask.nc
 # cdo ifthen landmask.nc -timmean mergetime_TAN_ANN.nc    land_mrgtim_TAN_ANN.nc


  
 ########################
 # Add discovery metadata
 # Change attributes.
 # Call:
 #ncatted -O -a long_name,elevation,o,c,"days with zero-crossings"       land_mrgtim_zerodeg.nc
 #ncatted -O -a short_name,elevation,o,c,"dzc"       land_mrgtim_zerodeg.nc
 #ncatted -O -a units,elevation,o,c,"days"       land_mrgtim_zerodeg.nc
 # NOTE: these lines will fail if they contain spaces. 
 ########################
 
     # Generate UUID
      uuid1=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid2=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid3=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid4=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid5=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid6=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid7=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid8=$(python -c 'import uuid; print(uuid.uuid4())')
      uuid9=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid10=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid11=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid12=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid13=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid14=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid15=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid16=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid17=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid18=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid19=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid20=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid21=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid22=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid23=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid24=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid25=$(python -c 'import uuid; print(uuid.uuid4())')
     uuid26=$(python -c 'import uuid; print(uuid.uuid4())')
     # uuid27=$(python -c 'import uuid; print(uuid.uuid4())')
     # echo $uuid1
                                      
 ncatted -O -a id,global,o,c,$uuid1   $savedir'/land_mrgtim_hdwi-nor'
# ncatted -O -a id,global,o,c,$uuid2   $savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'
# ncatted -O -a id,global,o,c,$uuid3   $savedir'/land_mrgtim_heatwave_index28X-3days.nc'
 ncatted -O -a id,global,o,c,$uuid4   $savedir'/land_mrgtim_TAN_ANN.nc'
 ncatted -O -a id,global,o,c,$uuid5   $savedir'/land_mrgtim_TAX_ANN.nc'
 ncatted -O -a id,global,o,c,$uuid6   $savedir'/land_mrgtim_TAN_DJF.nc'
 ncatted -O -a id,global,o,c,$uuid7   $savedir'/land_mrgtim_TAX_DJF.nc'
 ncatted -O -a id,global,o,c,$uuid8   $savedir'/land_mrgtim_TAN_MAM.nc'
 ncatted -O -a id,global,o,c,$uuid9   $savedir'/land_mrgtim_TAX_MAM.nc'
 ncatted -O -a id,global,o,c,$uuid10  $savedir'/land_mrgtim_TAN_JJA.nc'
 ncatted -O -a id,global,o,c,$uuid11  $savedir'/land_mrgtim_TAX_JJA.nc'
 ncatted -O -a id,global,o,c,$uuid12  $savedir'/land_mrgtim_TAN_SON.nc'
 ncatted -O -a id,global,o,c,$uuid13  $savedir'/land_mrgtim_TAX_SON.nc'
 ncatted -O -a id,global,o,c,$uuid14  $savedir'/land_mrgtim_DTR_ANN.nc'
 ncatted -O -a id,global,o,c,$uuid15  $savedir'/land_mrgtim_DTR_DJF.nc'
 ncatted -O -a id,global,o,c,$uuid16  $savedir'/land_mrgtim_DTR_MAM.nc'
 ncatted -O -a id,global,o,c,$uuid17  $savedir'/land_mrgtim_DTR_JJA.nc'
 ncatted -O -a id,global,o,c,$uuid18  $savedir'/land_mrgtim_DTR_SON.nc'
 ncatted -O -a id,global,o,c,$uuid19  $savedir'/land_mrgtim_zerodeg_DJF.nc'
 ncatted -O -a id,global,o,c,$uuid20  $savedir'/land_mrgtim_zerodeg_MAM.nc'
 ncatted -O -a id,global,o,c,$uuid21  $savedir'/land_mrgtim_zerodeg_JJA.nc'
 ncatted -O -a id,global,o,c,$uuid22  $savedir'/land_mrgtim_zerodeg_SON.nc'
 ncatted -O -a id,global,o,c,$uuid23  $savedir'/land_mrgtim_zerodeg_ANN.nc'
 ncatted -O -a id,global,o,c,$uuid24  $savedir'/land_mrgtim_tropnight.nc'
 ncatted -O -a id,global,o,c,$uuid25  $savedir'/land_mrgtim_fd.nc'
 ncatted -O -a id,global,o,c,$uuid26  $savedir'/land_mrgtim_summerd-nor.nc'


 ncatted -O -a long_name,tx,o,c,"Norwegian_heat_wave_duration_index" 	$savedir'/land_mrgtim_hdwi-nor'        #   heatwave_index_Tmax>28 Tmin>16 running mean 5 days" 	$savedir'/land_mrgtim_hdwi-nor'
# ncatted -O -a long_name,tx,o,c,"heatwave_index_Tmax>28 Tmin>16 running mean 3 days"   	$savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'
# ncatted -O -a long_name,tx,o,c,"heatwave_index_Tmax>28 running mean 3 days" 	$savedir'/land_mrgtim_heatwave_index28X-3days.nc'
 ncatted -O -a long_name,tn,o,c,"average_of_minimum_air_temperature" 	$savedir'/land_mrgtim_TAN_ANN.nc' 		
 ncatted -O -a long_name,tx,o,c,"average_of_maximum_air_temperature" 	$savedir'/land_mrgtim_TAX_ANN.nc' 		
 ncatted -O -a long_name,tn,o,c,"average_of_minimum_air_temperature" 	$savedir'/land_mrgtim_TAN_DJF.nc' 		
 ncatted -O -a long_name,tx,o,c,"average_of_maximum_air_temperature" 	$savedir'/land_mrgtim_TAX_DJF.nc' 		
 ncatted -O -a long_name,tn,o,c,"average_of_minimum_air_temperature" 	$savedir'/land_mrgtim_TAN_MAM.nc' 		
 ncatted -O -a long_name,tx,o,c,"average_of_maximum_air_temperature" 	$savedir'/land_mrgtim_TAX_MAM.nc' 		
 ncatted -O -a long_name,tn,o,c,"average_of_minimum_air_temperature" 	$savedir'/land_mrgtim_TAN_JJA.nc' 		
 ncatted -O -a long_name,tx,o,c,"average_of_maximum_air_temperature" 	$savedir'/land_mrgtim_TAX_JJA.nc' 		
 ncatted -O -a long_name,tn,o,c,"average_of_minimum_air_temperature" 	$savedir'/land_mrgtim_TAN_SON.nc' 		
 ncatted -O -a long_name,tx,o,c,"average_of_maximum_air_temperature" 	$savedir'/land_mrgtim_TAX_SON.nc' 		
 ncatted -O -a long_name,tx,o,c,"diurnal temperature range" 	$savedir'/land_mrgtim_DTR_ANN.nc' 		
 ncatted -O -a long_name,tx,o,c,"diurnal temperature range" 	$savedir'/land_mrgtim_DTR_DJF.nc' 		
 ncatted -O -a long_name,tx,o,c,"diurnal temperature range" 	$savedir'/land_mrgtim_DTR_MAM.nc' 		
 ncatted -O -a long_name,tx,o,c,"diurnal temperature range" 	$savedir'/land_mrgtim_DTR_JJA.nc' 		
 ncatted -O -a long_name,tx,o,c,"diurnal temperature range" 	$savedir'/land_mrgtim_DTR_SON.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_days_with_zero_crossings " 	$savedir'/land_mrgtim_zerodeg_DJF.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_days_with_zero_crossings" 	$savedir'/land_mrgtim_zerodeg_MAM.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_days_with_zero_crossings" 	$savedir'/land_mrgtim_zerodeg_JJA.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_days_with_zero_crossings" 	$savedir'/land_mrgtim_zerodeg_SON.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_days_with_zero_crossings" 	$savedir'/land_mrgtim_zerodeg_ANN.nc' 		
 ncatted -O -a long_name,tn,o,c,"number of tropical nights" 	$savedir'/land_mrgtim_tropnight.nc' 		
 ncatted -O -a long_name,tn,o,c,"number_of_frost_days_tasmin-below-0"  $savedir'/land_mrgtim_fd.nc' 		
 ncatted -O -a long_name,tx,o,c,"nordic_summer_days_tasmax-exceeding-20" 	$savedir'/land_mrgtim_summerd-nor.nc' 	
 
 # I terminalen:
 # ncatted -O -a long_name,tn,o,c,"average_of_TAN" 	land_mrgtim_TAN_ANN.nc 		
							
							
 ncatted -O -a short_name,tx,o,c,"hdwi-nor" 	$savedir'/land_mrgtim_hdwi-nor'	
# ncatted -O -a short_name,tx,o,c,"heatwave" 	$savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'
# ncatted -O -a short_name,tx,o,c,"heatwave" 	$savedir'/land_mrgtim_heatwave_index28X-3days.nc'
 ncatted -O -a short_name,tn,o,c,"tasmin" 	$savedir'/land_mrgtim_TAN_ANN.nc' 		
 ncatted -O -a short_name,tx,o,c,"tasmax" 	$savedir'/land_mrgtim_TAX_ANN.nc' 		
 ncatted -O -a short_name,tn,o,c,"tasmin" 	$savedir'/land_mrgtim_TAN_DJF.nc' 		
 ncatted -O -a short_name,tx,o,c,"tasmax" 	$savedir'/land_mrgtim_TAX_DJF.nc' 		
 ncatted -O -a short_name,tn,o,c,"tasmin" 	$savedir'/land_mrgtim_TAN_MAM.nc' 		
 ncatted -O -a short_name,tx,o,c,"tasmax" 	$savedir'/land_mrgtim_TAX_MAM.nc' 		
 ncatted -O -a short_name,tn,o,c,"tasmin" 	$savedir'/land_mrgtim_TAN_JJA.nc' 		
 ncatted -O -a short_name,tx,o,c,"tasmax" 	$savedir'/land_mrgtim_TAX_JJA.nc' 		
 ncatted -O -a short_name,tn,o,c,"tasmin" 	$savedir'/land_mrgtim_TAN_SON.nc' 		
 ncatted -O -a short_name,tx,o,c,"tasmax" 	$savedir'/land_mrgtim_TAX_SON.nc' 		
 ncatted -O -a short_name,tx,o,c,"dtr" 	$savedir'/land_mrgtim_DTR_ANN.nc' 		
 ncatted -O -a short_name,tx,o,c,"dtr" 	$savedir'/land_mrgtim_DTR_DJF.nc' 		
 ncatted -O -a short_name,tx,o,c,"dtr" 	$savedir'/land_mrgtim_DTR_MAM.nc' 		
 ncatted -O -a short_name,tx,o,c,"dtr" 	$savedir'/land_mrgtim_DTR_JJA.nc' 		
 ncatted -O -a short_name,tx,o,c,"dtr" 	$savedir'/land_mrgtim_DTR_SON.nc' 		
 ncatted -O -a short_name,tn,o,c,"dzc" 	$savedir'/land_mrgtim_zerodeg_DJF.nc' 		
 ncatted -O -a short_name,tn,o,c,"dzc" 	$savedir'/land_mrgtim_zerodeg_MAM.nc' 		
 ncatted -O -a short_name,tn,o,c,"dzc" 	$savedir'/land_mrgtim_zerodeg_JJA.nc' 		
 ncatted -O -a short_name,tn,o,c,"dzc" 	$savedir'/land_mrgtim_zerodeg_SON.nc' 		
 ncatted -O -a short_name,tn,o,c,"dzc" 	$savedir'/land_mrgtim_zerodeg_ANN.nc' 		
 ncatted -O -a short_name,tn,o,c,"tropnight" 	$savedir'/land_mrgtim_tropnight.nc' 		
 ncatted -O -a short_name,tn,o,c,"fd" 	$savedir'/land_mrgtim_fd.nc' 		
 ncatted -O -a short_name,tx,o,c,"summerd-nor" 	$savedir'/land_mrgtim_summerd-nor.nc' 	

 # I terminalen: 
 # ncatted -O -a short_name,tn,o,c,"tasmin" 	land_mrgtim_TAN_ANN.nc 		

							
 ncatted -O -a units,tx,o,c,"number of events"  $savedir'/land_mrgtim_hdwi-nor'		
# ncatted -O -a units,tx,o,c,"number of events"  $savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'	
# ncatted -O -a units,tx,o,c,"number of events"  $savedir'/land_mrgtim_heatwave_index28X-3days.nc'
 ncatted -O -a units,tn,o,c,"C" 	$savedir'/land_mrgtim_TAN_ANN.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_TAX_ANN.nc'		
 ncatted -O -a units,tn,o,c,"C" 	$savedir'/land_mrgtim_TAN_DJF.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_TAX_DJF.nc' 		
 ncatted -O -a units,tn,o,c,"C" 	$savedir'/land_mrgtim_TAN_MAM.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_TAX_MAM.nc' 		
 ncatted -O -a units,tn,o,c,"C" 	$savedir'/land_mrgtim_TAN_JJA.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_TAX_JJA.nc' 		
 ncatted -O -a units,tn,o,c,"C" 	$savedir'/land_mrgtim_TAN_SON.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_TAX_SON.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_DTR_ANN.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_DTR_DJF.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_DTR_MAM.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_DTR_JJA.nc' 		
 ncatted -O -a units,tx,o,c,"C" 	$savedir'/land_mrgtim_DTR_SON.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_zerodeg_DJF.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_zerodeg_MAM.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_zerodeg_JJA.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_zerodeg_SON.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_zerodeg_ANN.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_tropnight.nc' 		
 ncatted -O -a units,tn,o,c,"days" 	$savedir'/land_mrgtim_fd.nc' 		
 ncatted -O -a units,tx,o,c,"days" 	$savedir'/land_mrgtim_summerd-nor.nc' 		

 # I terminalen:
 # ncatted -O -a units,tn,o,c,"C" 	land_mrgtim_TAN_ANN.nc 		

							
							
ncrename -v tx,hdwi-nor  $savedir'/land_mrgtim_hdwi-nor'   $savedir'/sn2018v2005_hist_none_none_norway_1km_hdwi-nor_annual-mean_'$startyear'-'$endyear'.nc4'
#ncrename -v tx,heatwave  $savedir'/land_mrgtim_heatwave_index28X-16N-3days.nc'   $savedir'/sn2018v2005_hist_none_none_norway_1km_heatwave28X-16N-3days_annual-mean_'$startyear'-'$endyear'.nc4'
#ncrename -v tx,heatwave  $savedir'/land_mrgtim_heatwave_index28X-3days.nc'       $savedir'/sn2018v2005_hist_none_none_norway_1km_heatwave28X-3days_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tasmin	 	$savedir'/land_mrgtim_TAN_ANN.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmin_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,tasmax	 	$savedir'/land_mrgtim_TAX_ANN.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmax_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tasmin	 	$savedir'/land_mrgtim_TAN_DJF.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmin_winter-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,tasmax	 	$savedir'/land_mrgtim_TAX_DJF.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmax_winter-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tasmin	 	$savedir'/land_mrgtim_TAN_MAM.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmin_spring-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,tasmax	 	$savedir'/land_mrgtim_TAX_MAM.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmax_spring-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tasmin	 	$savedir'/land_mrgtim_TAN_JJA.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmin_summer-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,tasmax	 	$savedir'/land_mrgtim_TAX_JJA.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmax_summer-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tasmin	 	$savedir'/land_mrgtim_TAN_SON.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmin_autumn-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,tasmax	 	$savedir'/land_mrgtim_TAX_SON.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tasmax_autumn-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,dtr	 	$savedir'/land_mrgtim_DTR_ANN.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dtr_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,dtr	 	$savedir'/land_mrgtim_DTR_DJF.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dtr_winter-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,dtr	 	$savedir'/land_mrgtim_DTR_MAM.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dtr_spring-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,dtr	 	$savedir'/land_mrgtim_DTR_JJA.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dtr_summer-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,dtr	 	$savedir'/land_mrgtim_DTR_SON.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dtr_autumn-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,dzc	 	$savedir'/land_mrgtim_zerodeg_DJF.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dzc_winter-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,dzc	 	$savedir'/land_mrgtim_zerodeg_MAM.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dzc_spring-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,dzc	 	$savedir'/land_mrgtim_zerodeg_JJA.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dzc_summer-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,dzc	 	$savedir'/land_mrgtim_zerodeg_SON.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dzc_autumn-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,dzc	 	$savedir'/land_mrgtim_zerodeg_ANN.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_dzc_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,tropnight	$savedir'/land_mrgtim_tropnight.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_tropnight_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tn,fd	        $savedir'/land_mrgtim_fd.nc' 	 	        $savedir'/sn2018v2005_hist_none_none_norway_1km_fd_annual-mean_'$startyear'-'$endyear'.nc4'
ncrename -v tx,summerd-nor	$savedir'/land_mrgtim_summerd-nor.nc' 	 	$savedir'/sn2018v2005_hist_none_none_norway_1km_summerd-nor_annual-mean_'$startyear'-'$endyear'.nc4'
 
 
echo "End of script. Now, move to R to plot."  # see scripts in https://github.com/KSSno/KiN2100/tree/main/indices

