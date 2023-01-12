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

Utslippsscenario:
- rcp2.6 fra CMIP5
- rcp4.5 fra CMIP5
- SSP-3 7.0 fra CMIP6 (ikke tilgjengelig ennå)

CMIP5-hist går fram til og med 2014. For 2015–2020, bruk data fra rcp45.

Modellene hadgem-r1i1p1-rca og hadgem-r1i1p1-remo mangler årene 2099–2100. Analysene for slutten av århundret gjøres derfor for 2069–2098.

Modeller: 
- cnrm-r1i1p1-aladin
- ecearth-r12i1p1-rca
- ecearth-r12i1p1-cclm
- ecearth-r3i1p1-hirham
- hadgem-r1i1p1-rca
- hadgem-r1i1p1-remo
- mpi-r1i1p1-cclm
- mpi-r2i1p1-remo
- noresm-r1i1p1-rca
- noresm-r1i1p1-remo


Mye informasjon er også nedfelt i modelleringsprotokollen [https://docs.google.com/document/d/1hoZLle4HIcaEWp4OatRD7pxGqy1CkESc/]
