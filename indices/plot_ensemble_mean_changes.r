source("/data06/shh/KiN/scripts/plot/plot_runoff_eva_swe_indices_changes.R")

plotting_inds_relative_endering(2071, 2100, "run", "rcp26", "�r", "annual",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp45", "�r", "annual",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp45", "Vinter", "winter",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp45", "V�r", "spring",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp45", "Sommer", "summer",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp45", "H�st", "autumn",3, 5)

plotting_inds_relative_endering(2071, 2100, "run", "rcp26", "Vinter", "winter",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp26", "V�r","spring", 3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp26", "Sommer", "summer",3, 5)
plotting_inds_relative_endering(2071, 2100, "run", "rcp26", "H�st", "autumn",3, 5)

plotting_inds_relative_endering(2071, 2100, "eva", "rcp26", "�r","annual", 3, 5)
plotting_inds_relative_endering(2071, 2100, "eva", "rcp26", "Sommer", "summer",3, 5)
plotting_inds_relative_endering(2071, 2100, "eva", "rcp45", "�r", "annual", 3, 5)
plotting_inds_relative_endering(2071, 2100, "eva", "rcp45", "Sommer", "summer",3, 5)

plotting_inds_relative_endering(2071, 2100, "swe_max", "rcp26", "�r", "annual",3, 6)
plotting_inds_relative_endering(2071, 2100, "swe_max", "rcp45", "�r", "annual",3, 6)

plotting_inds_relative_endering(2071, 2100, "swe_ndogn_1cm", "rcp26", "�r", "annual",3, 5)
plotting_inds_relative_endering(2071, 2100, "swe_ndogn_1cm", "rcp45", "�r", "annual",3, 5)

plotting_inds_relative_endering(2071, 2100, "swe_ndogn_langrenn", "rcp26", "�r", "annual",3, 5)
plotting_inds_relative_endering(2071, 2100, "swe_ndogn_langrenn", "rcp45", "�r", "annual",3, 5)

plotting_inds_relative_endering(2071, 2100, "swe_ndogn_topptur", "rcp26", "�r","annual", 3, 5)
plotting_inds_relative_endering(2071, 2100, "swe_ndogn_topptur", "rcp45", "�r", "annual",3, 5)

plotting_inds_relative_endering(2071, 2100, "hsd", "rcp26", "Sommer", "summer",3, 5)
plotting_inds_relative_endering(2071, 2100, "hsd", "rcp45", "Sommer", "summer",3, 5)



########
source("/data06/shh/KiN/scripts/plot/plot_run_runoff_map_relative_abosulte.r")
plotting_inds_absolute_endering(2071, 2100, "run", "rcp45", "Vinter", 3, 5)
plotting_inds_absolute_endering(2071, 2100, "run", "rcp45", "V�r", 3, 5)
plotting_inds_absolute_endering(2071, 2100, "run", "rcp45", "Sommer", 3, 5)
plotting_inds_absolute_endering(2071, 2100, "run", "rcp45", "H�st", 3, 5)

plotting_inds_runoffmap_endering(2071, 2100, "run", "rcp45", "Vinter", 3, 5)
plotting_inds_runoffmap_endering(2071, 2100, "run", "rcp45", "V�r", 3, 5)
plotting_inds_runoffmap_endering(2071, 2100, "run", "rcp45", "Sommer", 3, 5)
plotting_inds_runoffmap_endering(2071, 2100, "run", "rcp45", "H�st", 3, 5)
plotting_inds_runoffmap(1991, 2020, "run", "rcp45", "annual", 3, 5)


