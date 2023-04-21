# KiN2100

Her jobber MET, NVE og NORCE sammen om script for å beregne og analysere klima- og hydrologiske framskrivninger, 
samt utledede indekser, i prosjektet Klima i Norge 2100.

Filer er organisert i forskjellige undermapper:
- [ESD](ESD) for empirisk-statistisk nedskalering
- [indices](indices) for beregning av klimaindekser
- [geoinfo](geoinfo) for regioninndeling, masker og shape-filer

Notér at dette området kun skal brukes til script og mindre datafiler som ikke varierer med tiden, f.eks. masker eller topografidatasett, mens større datafiler skal deles på ekstern PPI (LustreC).

For deg som ønsker å bidra med flere analysescript, vennligst ta kontakt med oskar.landgren@met.no

## Skal du analysere RCM-framskrivninger?

Perioder:
- Referanseperiode: 1991–2020
- Midten av århundret: 2041–2070
- Slutten av århundret: 2071–2100

Modellene hadgem-r1i1p1-rca og hadgem-r1i1p1-remo mangler årene 2099–2100. For disse to modellene gjøres analysene for slutten av århundret derfor for  2069–2098. Analysene for midten av århundret gjøres for 2039–2068. Tidsserier håndteres ved å putte inn 2021 og 2022 rett etter referanseperioden (rekkefølgen blir: 2020, 2021, 2022, 2021, 2022, 2023).


Utslippsscenario:
- rcp2.6 fra CMIP5
- rcp4.5 fra CMIP5
- SSP-3 7.0 fra CMIP6 (ikke tilgjengelig ennå)

CMIP5-hist går fram til og med 2006. Ved biasjustering er referanseperioden («hist») forlenget med data fra rcp45 fram til 2020 fordi det er nærmest de faktiske utslippene. Dette valget er allerede gjort ved biasjustering, men greit å være oppmerksom på at filene «hist» for perioden 2006-2020 er hentet fra rcp4.5. 


Modeller, CMIP5 (rcp2.6 og rcp4.5): 
- cnrm-r1i1p1-aladin    (1960 -  2100)
- ecearth-r12i1p1-rca     (1970-2100)
- ecearth-r12i1p1-cclm  (1960 -  2100)
- ecearth-r3i1p1-hirham (1960 -  2100)
- hadgem-r1i1p1-rca       (1970-2098)
- hadgem-r1i1p1-remo    (1960 - 2098)
- mpi-r1i1p1-cclm       (1960 -  2100)
- mpi-r2i1p1-remo       (1960 -  2100)
- noresm-r1i1p1-rca       (1970- 2100)
- noresm-r1i1p1-remo    (1960 -  2100)

De ulike modellene har litt forskjellig tidsperiode også etter biasjustering. Start derfor tidsserier i 1971.
HadGEM-modellene mangler 12 eller 13 måneder i slutten av perioden. HadGEM-modellene håndteres ved å putte inn 2021 og 2022 (se beskrivelse over).


Mye informasjon er også nedfelt i modelleringsprotokollen [https://docs.google.com/document/d/1hoZLle4HIcaEWp4OatRD7pxGqy1CkESc/]

## Landmasker

Husk å bruke ifthen (ikke mul) hvis du har en 0/1 mask.

 cdo ifthen kss2023_mask1km_norway.nc4 infile-med-naboland.nc outfile-uten-naboland.nc

Hvis du bruker cdo mul med 0/1 mask og har 0 verdier (e.g 0 summerdager), får du 0 over havet OG 0 hvor du har 0 verdiene. Hvis du bruker ifthen, får du NA over havet og 0 hvor du har 0 verdiene. (Men maskene her er NA/1 masker, da er cdo mul også greit.)

Fila geoinfo/kss2023_mask1km_norway.nc4 viser landmasken til seNorge-griddet.

Den er laget slik: 

cdo gec,0 kss2023_dem1km_all.nc4 kss2023_mask1km_norway.nc4

ncrename -v elevation,mask kss2023_mask1km_norway.nc4

ncatted -a standard_name,mask,o,c,"mask" -a units,mask,o,c,"1" kss2023_mask1km_norway.nc4




