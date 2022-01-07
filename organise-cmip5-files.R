## Organise CMIP5 files
## Create a folder with symbolic links where the file names follow the same structure as
## tas_Amon_NorESM2-LM_ssp245_r7i1p1f2_2015-2050.nc
## @RasmusBenestad, 2022-01-05

decipher <- function(x) {
  i <- gregexpr('_',x)[[1]]
  model <- substr(x,i[2]+1,i[3]-1)
  ssp <- substr(x,i[3]+1,i[4]-1)
  ripf <- substr(x,i[4]+1,i[4]+8)
  interval <- substr(x,i[5]+1,regexpr('.nc',x)[[1]]-1)
  return(c(model,ssp,ripf,interval))
}

path1 <- '~/data/CMIP/CMIP5.monthly/RCP45'
path0 <- '~/data/CMIP/CMIP5.monthly/rcp45'
if (!file.exists((path1))) dir.create(path1)
files0 <- list.files(path=path0,pattern='.nc')
for (file in files0) {
  X <- retrieve(paste(path0,file,sep='/'),lon=c(0,10),lat=c(0,10))
  model <- attr(X,'model_id')
  ripf <- attr(X,'parent_experiment_rip')
  interval <- paste(range(year(X)),collapse='-')
  rcp <- substr(file,regexpr('rcp',file),regexpr('rcp',file)+4)
  replacetext <- substr(file,regexpr('ens_',file),regexpr('.nc',file)-1)
  newname <- sub(replacetext,paste(model,rcp,ripf,interval,sep='_'),file)
  ## Check the names:
  print(c(file,newname))
  ## Create symbolic links:
  if (!file.exists(file.path(path1,newname))) 
    system(paste('ln -s ',file.path(path0,file),file.path(path1,newname)))
}