#!/bin/bash

# CALL:
#./temperature_indices_TAS.sh   ecearth-r3i1p1-hirham   1
#./temperature_indices_TAS.sh 	ecearth-r12i1p1-rca	1
#./temperature_indices_TAS.sh 	cnrm-r1i1p1-aladin	1
#./temperature_indices_TAS.sh 	ecearth-r12i1p1-cclm	1
#./temperature_indices_TAS.sh 	ecearth-r3i1p1-hirham	1
#./temperature_indices_TAS.sh 	hadgem-r1i1p1-rca	1
#./temperature_indices_TAS.sh 	hadgem-r1i1p1-remo	1
#./temperature_indices_TAS.sh 	mpi-r1i1p1-cclm	        1
#./temperature_indices_TAS.sh 	mpi-r2i1p1-remo	        1
#./temperature_indices_TAS.sh 	noresm-r1i1p1-rca	1
#./temperature_indices_TAS.sh 	noresm-r1i1p1-remo	1
#for m in $(seq 1 10); do
#    ./temperature_indices_TAS.sh $filedir/${model[$i-1]} 1
#done


# Run from l-klima-app05/hdata/hmdata/KiN2100/analyses/github/indices/
## or /hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/*_projections
# Remember to run from a screen terminal. This may take a while...
# Copied from testfolder "eqm" 2022-12-09. Last edited by IBNI 09-01-2023. 
set -e # denne stopper scriptet hvis det kommer en feilmelding.

echo "This program calculates temperature indicators from Tmean (tas; TG) from ONE 3dBC-model. This progam has two hard-coded arguments, on the form 'ecearth-r3i1p1-hirham' and '1'. Consider adding a third agrument '3dbc_projections' which can be swapped with 'eqm_projections', and a fourth: 'hist/rcp45/rcp85'. For the historical period, double-check that years cover 1960-2020."

mod=$1                   # 'ecearth-r12i1p1-rca'    # ecearth-r12i1p1-cclm      # ecearth-r3i1p1-hirham
bcm='eqm_projections'    # legg inn $2              # 3dbc_projections          # eqm_projections

if [ $bcm = '3dbc_projections' ]; then
    bcmdir='3dbc-eqm'
elif [ $bcm = 'eqm_projections' ]; then
    bcmdir='eqm'
else
    echo "Please check your argument bcm (bias-correction method) and file paths of filedir and savedir."
fi

rcp='rcp45'  # 'hist' 'rcp26' 'rcp45' 'rcp85'
startyr=2071 #1991 #2041 # 2071 1960
endyear=2100 #2020 #2070 # 2100 2014
echo "Argument 1 = " $mod
echo "                                  Check that there is no / after the model name!"
#echo "Argument 2 = " $bcm
echo "Argument 2 = 0 if you want to skip the processing, else 1. Now it is = " $2 
#echo "Argument 2 = " $rcp


#if [ $rcp == "hist" ]; then   # gjelder CMIP5
#  years=$(seq 1971 2005)
#else
#  years=$(seq 2006 2100)
#fi

if [ $mod = 'cnrm-r1i1p1-aladin' ]; then      # KiN-2015: CNRM-CCLM
   modname=cnrm-r1i1p1-aladin
elif [ $mod = 'ecearth-r12i1p1-cclm' ]; then  # KiN-2015: CNRM-RCA
   modname=ecearth-r12i1p1-cclm
elif [ $mod = 'ecearth-r12i1p1-rca' ]; then   # KiN-2015: EC-CCLM
   modname=ecearth-r12i1p1-rca
elif [ $mod = 'ecearth-r3i1p1-hirham' ]; then # KiN-2015: EC-HIRHAM
   modname=ecearth-r3i1p1-hirham
elif [ $mod = 'hadgem-r1i1p1-rca' ]; then     # KiN-2015: EC-RACMO
    modname=hadgem-r1i1p1-rca
    if [ $endyear = 2100 ]; then
       startyr=2069
       endyear=2098
    fi   
elif [ $mod = 'hadgem-r1i1p1-remo' ]; then    # KiN-2015: EC-RCA
    modname=hadgem-r1i1p1-remo
    if [ $endyear = 2100 ]; then
	startyr=2069
	endyear=2098
    fi
elif [ $mod = 'mpi-r1i1p1-cclm' ]; then       # KiN-2015: HADGEM-RCA
   modname=mpi-r1i1p1-cclm
elif [ $mod = 'mpi-r2i1p1-remo' ]; then       # KiN-2015: IPSL-RCA
   modname=mpi-r2i1p1-remo
elif [ $mod = 'noresm-r1i1p1-rca' ]; then     # KiN-2015: MPI-CCLM
   modname=noresm-r1i1p1-rca
elif [ $mod = 'noresm-r1i1p1-remo' ]; then    # KiN-2015: MPI-RCA
   modname=noresm-r1i1p1-remo
fi

#$longname=$( 'name1' 'name2' )
#$shortname=$( 'mn1', 'mn2' )

#mkdir  ecearth-r12i1p1-rca
#mkdir  hadgem-r1i1p1-rca
#mkdir  hadgem-r1i1p1-remo
#mkdir  noresm-r1i1p1-rca
#mkdir  cnrm-r1i1p1-aladin
#mkdir  mpi-r1i1p1-cclm
#mkdir  mpi-r2i1p1-remo
#mkdir  noresm-r1i1p1-remo
#mkdir  ecearth-r3i1p1-hirham
#mkdir  ecearth-r12i1p1-cclm

filedir='/hdata/hmdata/KiN2100/ForcingData/BiasAdjust/'$bcmdir'/netcdf/'
## OLD testdir? filedir='/data07/KiN2100/ForcingData/BiasAdjust/eqm/netcdf/'
##filedir='/hdata/hmdata/KiN2100/analyses/indicators/atm/'


# Note that projections (eqm and 3DBC) gives temperature in Kelvin; seNorge in degrees C.
#filedir='/hdata/hmdata/KiN2100/ForcingData/ObsData/seNorge2018_v20.05/netcdf/' # seNorge


savedir='/hdata/hmdata/KiN2100/analyses/indicators/temperature_indices/'$bcm'/'$mod


#delete?
#if [ "$startyr" == 1960 ]; then 
#   echo 'Testing the syntax of an if sentence. Now, the loop below should work'
#else
#   echo 'even when it is false.'
#fi





years=$(seq $startyr $endyear)             # $(seq 1960 2014)

#if [ $y == 2015 ] || [ $y == 2016 ] || [ $y == 2017 ] || [ $y == 2018 ] || [ $y == 2019 ] || [ $y == 2020 ]; then
#    rcp='rcp45'
#    echo 'RCP = ' $rcp
#else         # Fjern disse når 2015-2020 er kjørt!
#    echo 'Im lazy, so Im skipping this year: ' $y
#fi


    
  # Loop over years
 for y in $years; do
    echo $y

    if [ $2 = "1" ]; then

      if [ $rcp = "hist" ]; then
      # First add a switch from "hist" to "rcp45" for the years 2015-2020. Also note that the years after 2006 stored under 'hist' [1] have taken data from rcp45. Thus, all data from 2006 are from rcp45
      # [1] /hdata/hmdata/KiN2100/ForcingData/BiasAdjust/3dbc-eqm/netcdf//hadgem-r1i1p1-rca/tas/hist/*2014.n
          if [ $y -ge 2015 ] && [ $y -le 2021 ]; then
            rcp='rcp45'
            echo 'RCP = ' $rcp
          else
            rcp='hist'  
            echo 'RCP = ' $rcp
          fi       # end if $years =2015-2020
      fi           # end if $rcp=hist  

       ifileG=$filedir'/'$mod'/tas/'$rcp'/'$mod'_'$rcp'_'$bcmdir'-sn2018v2005_rawbc_norway_1km_tas_daily_'$y'.nc4' # Tmean, daily mean temperature, not needed
       # Tmax,  daily min temperature
       # ifileX=$filedir'/'$mod'/tasmax/'$rcp'/'$mod'_'$rcp'_eqm-sn2018v2005_rawbc_norway_1km_tasmax_daily_'$y'.nc4'
       ### ifileX=$filedir'/'$mod'/tasmax/hist/'$mod'_hist_3dbc-eqm-sn2018v2005_rawbc_norway_1km_tasmax_daily_'$y'.nc4'
       # Tmin,  daily min temperature
       # ifileN=$filedir'/'$mod'/tasmin/'$rcp'/'$mod'_'$rcp'_eqm-sn2018v2005_rawbc_norway_1km_tasmin_daily_'$y'.nc4' 
       ## #ifileN=$filedir'/'$mod'/tasmin/hist/'$mod'_hist_3dbc-eqm-sn2018v2005_rawbc_norway_1km_tasmin_daily_'$y'.nc4' 
       #echo $ifileX
     echo "Done reading in temperature variables for year" $y

   
# ##   mon=$(seq 1 12)   # $(seq 1 12)
# ##   for mon in $mon; do


     ## Vekstsesong
     # Beholder denne inntil videre, men skal nok erstattes med OETs beregning av vekstsesong fra normaler (altså gjennomsnittstemperatur i et intervall +- 15 dager).
     # Antall dager med TAM>=5 over (gec) året ("vekstsesong")
     # cdo timsum -gec,5 $ifileG  $savedir'/'$y'_growing_days.nc'
     # echo 'These lines produced an HDF error. They are therefore placed on top.'
     # Solve the HDF error by 1) adding $savedir/ before your filename!
     # and 2) by treating the output from eca_gsl (tmp1.nc) as a file with two fields.
     ## cdo timsum -gec,278 $ifileG  $savedir'/tmp1.nc'
     echo 'Beregner vekstsesong med:'
     echo 'cdo eca_gsl ' $ifileG $savedir'/../../landmask_kun_Norge.nc' $savedir'/tmp1.nc'

     cdo eca_gsl $ifileG $savedir'/../../landmask_kun_Norge.nc' $savedir'/tmp1.nc'
     echo 'eca_gsl gives a different format than the other lines. Extract the field thermal_growing_season_length.'
   
     cdo setname,'growing_season_length' -setunit,'days' -selvar,'thermal_growing_season_length' $savedir'/tmp1.nc' $savedir'/'$y'_growing_season_length.nc'

     ## Fyringssesong (nedprioritert, 3. pri. Klemmer ut heating days med terskel 10 grader likevel, når jeg først er i gang).
      # Antall dager med TAM<=10 (lec) over året
      # cdo timsum -lec,10 $ifileG  $savedir'/'$y'_heating_days.nc'

      cdo timsum -lec,283.15 $ifileG $savedir'/tmp1.nc'
      cdo setname,'heating_days' -setunit,'days' $savedir'/tmp1.nc' $savedir'/'$y'_heating_days.nc'


     
      ## Avkjølingssesong
      # Beholder denne inntil videre, men det er nok energibehovet, dvs graddagene, de er interessert i.
      # Antall dager med TAM>=22 (gec) over året.
      # NB! eca_gsl takes the threshold as degrees CELCIUS but the input data is in Kelvin.
      # This function takes in days as the first argument and temperature in Kelvin as the second.
      # see https://earth.bsc.es/gitlab/ces/cdo/raw/b4f0edf2d5c87630ed4c5ddee5a4992e3e08b06a/doc/cdo_eca.pdf
     # 5 days= first occurrence of 5 consecutive days over the given threshold 22. 
      cdo eca_gsl,5,22 $ifileG   $savedir'/../../landmask_kun_Norge.nc'  $savedir'/tmp1.nc'
      cdo setname,'cooling_season_length' -setunit,'days' $savedir'/tmp1.nc' $savedir'/'$y'_cooling_season_length.nc'


     
     # Tetraterm, average of the four warmest months
     cdo timmean -selmon,6/9 $ifileG $savedir'/tmp1.nc'
     cdo setname,'tetraterm' -setunit,'Kelvin' $savedir'/tmp1.nc' $savedir'/'$y'_tetraterm_timmean_6-9.nc'
     
     ## Tetraterm_cold, average of the four coldest months
     # cdo timmean -selmon,11,12,1,2   $ifileG $savedir'/'$y'_tetraterm_cold_timmean_11-2.nc'
     ## Pentaterm_cold, average of the five coldest months
     # cdo timmean -selmon,11,12,1,2,3 $ifileG $savedir'/'$y'_pentaterm_cold_timmean_11-3.nc'
     ## Pentaterm, average of the five warmest months
     # cdo timmean -selmon,5/9        $ifileG $savedir'/'$y'_pentaterm_timmean_5-9.nc'

     # Gjennomsnitt av tas

      cdo timmean $ifileG  $savedir'/'$y'_tas_timmean.nc'  #tmp1.nc'
      # cdo setname,'tas' -setunit,'Kelvin' $savedir'/tmp1.nc' $savedir'/'$y'_tas_timmean.nc' # not needed

      cdo timmean -selmon,12,1,2 $ifileG $savedir'/'$y'_tas_timmean_DJF.nc'
      cdo timmean -selmon,3/5    $ifileG $savedir'/'$y'_tas_timmean_MAM.nc'
      cdo timmean -selmon,6/8    $ifileG $savedir'/'$y'_tas_timmean_JJA.nc'
      cdo timmean -selmon,9/11   $ifileG $savedir'/'$y'_tas_timmean_SON.nc'
      # Vintersesongen her er forenklet fordi formålet er å skaffe statistikk.
      # For effektforskere som er interessert i konstinuerlige tidsserier, er denne beregningen av vintersesong feil.
      # Bedre praksis er å slå sammen alle filene først, og deretter beregne cdo seasmean. Da kommer alle fire feltene.

      ## Avkjølingsgraddager, cooling days
      # Antall dager med TAM>=22 (gec) over året
      #cdo timsum -gec,22 $ifileG  $savedir'/'$y'_cooling_days.nc'
      
      cdo timsum -setrtoc,-Inf,0,0 -subc,295.15 $ifileG  $savedir'/tmp1.nc'
      cdo setname,'cooling_days' -setunit,'days' $savedir'/tmp1.nc' $savedir'/'$y'_cdd.nc'  # denne burde ikke hete cdd, fordi det kan blandes med consecutive dry days.


      ## Varme dager (slettes)
      # Antall dager med TAM>20 (gtc) over året (står ikke på indikatorlista)
      # cdo timsum -gtc,20 $ifileG  $savedir'/'$y'_warm_days.nc'
      # 
      # cdo timsum -gtc,293.15 $ifileG  $savedir'/tmp1.nc'
      # cdo setname,'warm_days' -setunit,'days' $savedir'/tmp1.nc' $savedir'/'$y'_warm_days.nc'


      ## Fyringssesong
      # Antall dager med TAM<=10 (lec) over året (står ikke på indikatorlista)
      # Må avklare om vi trenger glidende middel for minst N dager på rad. Hør med Andreas og Inger.
      # Konklusjon: Denne fjernes.
      # Det er ikke behov for å beregne fyringssesong på andre måter enn energigradtall/fyringsgraddager (hdd).
      #      cdo timsum -lec,283.15 $ifileG  $savedir'/tmp1.nc'
      #      cdo setname,'heating_days' -setunit,'days' $savedir'/tmp1.nc' $savedir'/'$y'_heating_days.nc'

     
     
      # Vekstgraddager >=5 C (altså 278 Kelvin)
      # cdo timsum -setrtoc,-Inf,0,0 -addc,-5 tam.nc gdd.nc
      
      cdo timsum -setrtoc,-Inf,0,0 -addc,-278.15 $ifileG $savedir'/tmp1.nc'
      cdo setname,'growingdegreedays' -setunit,'degreedays' $savedir'/tmp1.nc' $savedir'/'$y'_gdd.nc'


      
      # Fyringsgraddager <=17 C i fyringssesongen (altså 290 Kelvin)
      # Igjen er inputtemperatur i Kelvin og terskelen i Celcius
      # cdo eca_hd tam.nc hdd.nc

      cdo eca_hd,17,17 $ifileG $savedir'/tmp1.nc'
      cdo setname,'heatingdegreedays' -setunit,'degreedays' $savedir'/tmp1.nc' $savedir'/'$y'_hdd.nc'

      
       echo 'done calculating annual values  of indices. Now combine into 30-year means.'


#*      else         # Fjern disse når 2015-2020 er kjørt!
#*	  echo 'Im lazy, so Im skipping this year: ' $y
#*      fi       # end if $years =2015-2020
      
    fi       # end testing-if-sentencene  if [ $2 == 1 ]





      
   done        # end for years

echo 'Done looping over years. The years processed were:' $years



# Combine monthly files into one file using mergetime (this is the only command working)
# ##for mon in {1..12}; do
     cdo mergetime $savedir'/'*'_growing_season_length.nc' $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_cooling_season_length.nc' $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tetraterm_timmean_6-9.nc' $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tas_timmean.nc' $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tas_timmean_DJF.nc' $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tas_timmean_MAM.nc' $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tas_timmean_JJA.nc' $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_tas_timmean_SON.nc' $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_growing_days.nc' $savedir'/growing_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_cooling_days.nc' $savedir'/cooling_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_energy_days.nc' $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_heating_days.nc' $savedir'/heating_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     cdo mergetime $savedir'/'*'_warm_days.nc' $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_tas_p25_timpctl.nc'  $savedir'/tas_p25_mergetime_timpctl_'$startyr'-'$endyear'.nc'
##     cdo mergetime $savedir'/'*'_tas_p75_timpctl.nc'  $savedir'/tas_p75_mergetime_timpctl_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_gdd.nc' $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_hdd.nc' $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     cdo mergetime $savedir'/'*'_cdd.nc' $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     

#cdo mergetime $savedir'/'*'__days.nc' $savedir'/days_mergetime_timsum_'$startyr'-'$endyear'.nc'     

     rm $savedir'/2'*'.nc'       # These filenames start with 2100, 2099 and so on. REMEMBER TO INCLUDE "2" at the start!
#     rm $savedir'/2'*'tim*'.nc'   
     #rm $savedir'/2'*'length.nc'                # 'pctl.nc'
     rm $savedir'/tmp1.nc'

     if [ $startyr = 1991 ]; then
	 rm $savedir'/199'*'.nc'
     fi
     
     # ##done

     # Add discovery metadata
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
#     uuid12=$(python -c 'import uuid; print(uuid.uuid4())')
#     uuid13=$(python -c 'import uuid; print(uuid.uuid4())')
#     uuid14=$(python -c 'import uuid; print(uuid.uuid4())')
#     uuid15=$(python -c 'import uuid; print(uuid.uuid4())')
#     uuid16=$(python -c 'import uuid; print(uuid.uuid4())')

     echo $uuid1
     
     ncatted -O -a id,global,o,c,$uuid1  $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid2  $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid3  $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid4  $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid5  $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid6  $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid7  $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid8  $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid9  $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid10 $savedir'/heating_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid11 $savedir'/winter_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid12 $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid13 $savedir'/tas_p25_mergetime_timpctl_'$startyr'-'$endyear'.nc'
#     ncatted -O -a id,global,o,c,$uuid14 $savedir'/tas_p75_mergetime_timpctl_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid15 $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid16 $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     ncatted -O -a id,global,o,c,$uuid15 $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
##     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/growing_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     ncatted -O -a naming_authority,global,o,c,"no.nve"  $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'

     date=$(date +'%Y-%m-%d')     


     ncatted -O -a date_created,global,o,c,$date  $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
##     ncatted -O -a date_created,global,o,c,$date  $savedir'/growing_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a date_created,global,o,c,$date  $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     ncatted -O -a date_created,global,o,c,$date  $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     ncatted -O -a date_created,global,o,c,$date  $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     
     ncatted -O -a units,global,o,c,"days" $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"days" $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"K" $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
##     ncatted -O -a units,global,o,c,"days" $savedir'/growing_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a units,global,o,c,"days" $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     ncatted -O -a units,global,o,c,"days" $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
      ncatted -O -a units,global,o,c,"degreedays" $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"degreedays" $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     ncatted -O -a units,global,o,c,"degreedays" $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     

     ncatted -O -a long_name,global,o,c,"Mean annual growing season (days>5C)" $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean annual cooling days (days>=22C)" $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Tetraterm: Mean seasonal near surface temperature (2m) from June to September" $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean seasonal near surface temperature (2m)" $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean seasonal near surface temperature (2m) for winter" $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean seasonal near surface temperature (2m) for spring" $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean seasonal near surface temperature (2m) for summer" $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Mean seasonal near surface temperature (2m) for autumn" $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc'
##     ncatted -O -a long_name,global,o,c,"" $savedir'/growing_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
#     ncatted -O -a long_name,global,o,c,"Mean annual number of warm days (>20C)" $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
##     ncatted -O -a long_name,global,o,c,"Mean annual energy days (days<=17C)" $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Growing degree-days (>5C)" $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Heating degree-days (<17C)" $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc'
     ncatted -O -a long_name,global,o,c,"Cooling degree-days (>=22C)" $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc'

     
     
#    # Change variable-specific attributes
     #ncatted -O -a long_name,dtr,o,c,"diurnal temperature range" $savedir'/DTR_mergetime_monmean_'$startyr'-'$endyear'.nc'
     #ncatted -O -a long_name,dzc,o,c,"number of days with zero crossings" $savedir'/DZC_mergetime_monsum_'$startyr'-'$endyear'.nc'
     ### ncatted -O -a long_name,frost,o,c,"number of days with frost" $savedir'/frostnum_mergetime_monsum_'$startyr'-'$endyear'.nc'
     #ncatted -O -a long_name,frostinGrow,o,c,"number of frostdays in growing season" $savedir'/frostinGrow_mergetime_monsum_'$startyr'-'$endyear'.nc'
     #ncatted -O -a long_name,heat20C,o,c,"number of 3 consecutive days above 20 degC" $savedir'/heat20_mergetime_monsum_'$startyr'-'$endyear'.nc'
     ### ncatted -O -a long_name,heat28C,o,c,"number of 3 consecutive days above 28 degC" $savedir'/heat28_mergetime_monsum_'$startyr'-'$endyear'.nc'

     
 echo 'Now, remember to move the resulting mergetime files into a folder named after the model, and remove *monsum.nc'

# # # Calculate the long-term mean of annual sums (=yearsum)
# # # Note the different timesteps.
# # # 1960-1984 is  1/23 i 3dBC og  4/28 i senorge,
# # # 1985-2014 is 24/53 i 3dBC og 29/58 i senorge,
# # # 1971-2020 is 10/39 i 3dBC og 15/44 i senorge

 if [ "$startyr" == 1960 ]; then
     echo 'DENNE BESVERGELSEN FUNKER IKKE, SÅ IKKE BRUK STARTAAR 1960'
     cdo timmean -seltimestep,1/23 -yearmean $savedir'/DTR_mergetime_monmean_'$startyr'-'$endyear'.nc' $savedir'/DTR_timmean_yrmean_mgtim_mmean_1960-1984.nc'
     cdo timmean -seltimestep,24/53 -yearmean $savedir'/DTR_mergetime_monmean_'$startyr'-'$endyear'.nc' $savedir'/DTR_timmean_yrmean_mgtim_mmean_1985-2014.nc'
    # cdo timmean -seltimestep,1/23 -yearsum $savedir'/DZC_mergetime_monsum_1960-2014.nc' $savedir'/DZC_timmean_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timmean -seltimestep,24/53 -yearsum $savedir'/DZC_mergetime_monsum_1960-2014.nc' $savedir'/DZC_timmean_yrsum_mgtim_msum_1985-2014.nc'

     cdo timmean -seltimestep,1/23 -yearsum $savedir'/frostinGrow_mergetime_monsum_1960-2014.nc' $savedir'/frostinGrow_timmean_yrsum_mgtim_msum_1960-1984.nc'
     cdo timmean -seltimestep,24/53 -yearsum $savedir'/frostinGrow_mergetime_monsum_1960-2014.nc' $savedir'/frostinGrow_timmean_yrsum_mgtim_msum_1985-2014.nc'
 
    # cdo timmean -seltimestep,1/23 -yearsum $savedir'/heat20_mergetime_monsum_1960-2014.nc' $savedir'/heat20_timmean_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timmean -seltimestep,24/53 -yearsum $savedir'/heat20_mergetime_monsum_1960-2014.nc' $savedir'/heat20_timmean_yrsum_mgtim_msum_1985-2014.nc'
    # cdo timmean -seltimestep,1/23 -yearsum $savedir'/heat28_mergetime_monsum_1960-2014.nc' $savedir'/heat28_timmean_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timmean -seltimestep,24/53 -yearsum $savedir'/heat28_mergetime_monsum_1960-2014.nc' $savedir'/heat28_timmean_yrsum_mgtim_msum_1985-2014.nc'

    # # I terminalen:
    # # cdo timmean -seltimestep,1/23 -yearsum DZC_mergetime_monsum_1960-2014.nc DZC_timmean_yrsum_mgtim_msum_1960-1984.nc
    # # cdo timmean -seltimestep,24/53 -yearsum DZC_mergetime_monsum_1960-2014.nc DZC_timmean_yrsum_mgtim_msum_1985-2014.nc
    # # cdo timmean -seltimestep,10/39 -yearsum DZC_mergetime_monsum_1960-2014.nc DZC_timmean_yrsum_mgtim_msum_1971-2000.nc

    cdo timstd1 -seltimestep,1/23 -yearmean $savedir'/DTR_mergetime_monmean_1960-2014.nc' $savedir'/DTR_timstd1_yrmean_mgtim_mmean_1960-1984.nc'
    cdo timstd1 -seltimestep,24/53 -yearmean $savedir'/DTR_mergetime_monmean_1960-2014.nc' $savedir'/DTR_timstd1_yrmean_mgtim_mmean_1985-2014.nc'

    # cdo timstd1 -seltimestep,1/23 -yearsum $savedir'/DZC_mergetime_monsum_1960-2014.nc' $savedir'/DZC_timstd1_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timstd1 -seltimestep,24/53 -yearsum $savedir'/DZC_mergetime_monsum_1960-2014.nc' $savedir'/DZC_timstd1_yrsum_mgtim_msum_1985-2014.nc'

    cdo timstd1 -seltimestep,1/23 -yearsum $savedir'/frostinGrow_mergetime_monsum_1960-2014.nc' $savedir'/frostinGrow_timstd1_yrsum_mgtim_msum_1960-1984.nc'
    cdo timstd1 -seltimestep,24/53 -yearsum $savedir'/frostinGrow_mergetime_monsum_1960-2014.nc' $savedir'/frostinGrow_timstd1_yrsum_mgtim_msum_1985-2014.nc'

    # cdo timstd1 -seltimestep,1/23 -yearsum $savedir'/heat20_mergetime_monsum_1960-2014.nc' $savedir'/heat20_timstd1_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timstd1 -seltimestep,24/53 -yearsum $savedir'/heat20_mergetime_monsum_1960-2014.nc' $savedir'/heat20_timstd1_yrsum_mgtim_msum_1985-2014.nc'
    # cdo timstd1 -seltimestep,1/23 -yearsum $savedir'/heat28_mergetime_monsum_1960-2014.nc' $savedir'/heat28_timstd1_yrsum_mgtim_msum_1960-1984.nc'
    # cdo timstd1 -seltimestep,24/53 -yearsum $savedir'/heat28_mergetime_monsum_1960-2014.nc' $savedir'/heat28_timstd1_yrsum_mgtim_msum_1985-2014.nc'

 else
     
     cdo timmean $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc' $savedir'/gsl_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1 $savedir'/growing_season_length_mergetime_eca-gsl_'$startyr'-'$endyear'.nc' $savedir'/gsl_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'
     cdo timmean $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/cooling_season_length_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1 $savedir'/cooling_season_length_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/cooling_season_length_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

     cdo timmean $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc' $savedir'/tetraterm_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1 $savedir'/tetraterm_mergetime_timmean_6-9_'$startyr'-'$endyear'.nc' $savedir'/tetraterm_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

     cdo timmean  $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc' $savedir'/tas_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/tas_mergetime_timmean_'$startyr'-'$endyear'.nc' $savedir'/tas_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

     cdo timmean  $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc' $savedir'/tas_DJF_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/tas_mergetime_timmean_DJF_'$startyr'-'$endyear'.nc' $savedir'/tas_DJF_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

     cdo timmean  $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc' $savedir'/tas_MAM_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/tas_mergetime_timmean_MAM_'$startyr'-'$endyear'.nc' $savedir'/tas_MAM_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'
     
     cdo timmean  $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc' $savedir'/tas_JJA_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/tas_mergetime_timmean_JJA_'$startyr'-'$endyear'.nc' $savedir'/tas_JJA_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

     cdo timmean  $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc' $savedir'/tas_SON_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/tas_mergetime_timmean_SON_'$startyr'-'$endyear'.nc' $savedir'/tas_SON_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

##     cdo timmean  $savedir'/growing_days_mergetime_timmean_'$startyr'-'$endyear'.nc' $savedir'/growing_30-yrmean_mgtim_timmean_'$startyr'-'$endyear'.nc'
##     cdo timstd1  $savedir'/growing_days_mergetime_timmean_'$startyr'-'$endyear'.nc' $savedir'/growing_30-yrstd1_mgtim_timmean_'$startyr'-'$endyear'.nc'
#     cdo timmean  $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/warm_30-yrmean_mgtim_timsum_'$startyr'-'$endyear'.nc'
#     cdo timstd1  $savedir'/warm_days_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/warm_30-yrstd1_mgtim_timsum_'$startyr'-'$endyear'.nc'
##     cdo timmean  $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/energy_30-yrmean_mgtim_timsum_'$startyr'-'$endyear'.nc'
##     cdo timstd1  $savedir'/energy_days_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/energy_30-yrstd1_mgtim_timsum_'$startyr'-'$endyear'.nc'
     cdo timmean  $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/gdd_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/gdd_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/gdd_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'
     cdo timmean  $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc' $savedir'/hdd_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/hdd_mergetime_eca-hd_'$startyr'-'$endyear'.nc' $savedir'/hdd_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'
     # Det kan hende at denne skal være timsum, for den gir veldig lave tall.
     cdo timmean  $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/cdd_30-yrmean_mgtim_'$startyr'-'$endyear'.nc'
     cdo timstd1  $savedir'/cdd_mergetime_timsum_'$startyr'-'$endyear'.nc' $savedir'/cdd_30-yrstd1_mgtim_'$startyr'-'$endyear'.nc'

 fi   # ends startyear==1960


 # Create symbolic links from the 2069-2098 files in the hadgem folders to 2071-2100, to ease automation.
 if [ $mod = 'hadgem-r1i1p1-rca' ] || [ $mod = 'hadgem-r1i1p1-remo' ]; then
     ln -s $savedir'/tetraterm_30-yrmean_mgtim_2069-2098.nc' $savedir'/tetraterm_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/tas_30-yrmean_mgtim_2069-2098.nc' $savedir'/tas_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/tas_MAM_30-yrmean_mgtim_2069-2098.nc' $savedir'/tas_MAM_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/tas_JJA_30-yrmean_mgtim_2069-2098.nc' $savedir'/tas_JJA_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/tas_SON_30-yrmean_mgtim_2069-2098.nc' $savedir'/tas_SON_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/tas_DJF_30-yrmean_mgtim_2069-2098.nc' $savedir'/tas_DJF_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/cdd_30-yrmean_mgtim_2069-2098.nc' $savedir'/cdd_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/gdd_30-yrmean_mgtim_2069-2098.nc' $savedir'/gdd_30-yrmean_mgtim_2071-2100.nc'
     ln -s $savedir'/hdd_30-yrmean_mgtim_2069-2098.nc' $savedir'/hdd_30-yrmean_mgtim_2071-2100.nc'
 fi
 

   # rm $savedir'/2'*'tim'*'.nc'
   # rm $savedir'/2'*'dd.nc'  
 
 echo "End of script."

#else         # Fjern disse når 2015-2020 er kjørt!
#    echo 'Im lazy, so Im skipping this year: ' $y
#fi

 
 echo 'Det funker, det her! Peace out.'


