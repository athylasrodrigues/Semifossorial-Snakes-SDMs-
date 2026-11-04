# =============================================================================
# Atractus ronnie — ecological niche modeling workflow
# Repository: Semifossorial-Snakes-SDMs
#
# This script is a cleaned and reorganized version of the exploratory script
# supplied by the author. It is NOT yet a fully executable end-to-end pipeline:
# input paths, exact final predictor set, climate-model/scenario choices, and
# some biomod2 options must be checked against the final manuscript/data.
#
# Important:
# - Do not run this script unchanged until the CONFIG section is edited.
# - Keep all environmental predictors aligned to the same CRS, resolution,
#   extent, and grid before model calibration/projection.
# - Avoid mixing exploratory alternative workflows in the final analysis.
# =============================================================================


# -----------------------------------------------------------------------------
# 0. CONFIGURATION
# -----------------------------------------------------------------------------

# Set project root to the repository directory (prefer relative paths).
# Example:
# project_dir <- "C:/Users/Atilas_Rodrigues/Downloads/Semifossorial-Snakes-SDMs"
project_dir <- "."

dir_data_occ <- file.path(project_dir, "data", "occurrence_records")
dir_data_env <- file.path(project_dir, "data", "environmental_predictors")
dir_data_future <- file.path(project_dir, "data", "climate_scenarios", "future")
dir_data_past <- file.path(project_dir, "data", "climate_scenarios", "past")
dir_output <- file.path(project_dir, "outputs")

dir.create(dir_output, recursive = TRUE, showWarnings = FALSE)

# Study-area extent used in the supplied script (WGS84 longitude/latitude).
study_extent <- terra::ext(-43, -37, -8, -3)

# Occurrence file: expected columns Longitude and Latitude.
occurrence_file <- file.path(dir_data_occ, "Atractus1.txt")

# Set to TRUE only after checking that these paths and data are correct.
RUN_MODELING <- FALSE
RUN_PROJECTIONS <- FALSE


# -----------------------------------------------------------------------------
# 1. PACKAGES
# -----------------------------------------------------------------------------

required_packages <- c(
  "biomod2", "ggplot2", "terra", "raster", "sf", "geodata",
  "spThin", "usdm", "psych", "ade4", "factoextra", "tidyterra",
  "patchwork", "writexl"
)

# Install packages separately if necessary; avoid automatic installation in a
# publication workflow.
invisible(lapply(required_packages, function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Package not installed: ", pkg)
  }
}))

library(biomod2)
library(ggplot2)
library(terra)
library(raster)
library(sf)
library(geodata)
library(usdm)


# -----------------------------------------------------------------------------
# 2. OCCURRENCE DATA
# -----------------------------------------------------------------------------

if (!file.exists(occurrence_file)) {
  stop("Occurrence file not found: ", occurrence_file,
       "\nUpdate occurrence_file in the CONFIG section.")
}

occ <- read.csv(occurrence_file, header = TRUE)

required_occ_cols <- c("Longitude", "Latitude")
missing_occ_cols <- setdiff(required_occ_cols, names(occ))
if (length(missing_occ_cols) > 0) {
  stop("Occurrence table is missing required columns: ",
       paste(missing_occ_cols, collapse = ", "))
}

occ <- occ[complete.cases(occ[, required_occ_cols]), ]
occ$presence <- 1

summary(occ)
head(occ)


# -----------------------------------------------------------------------------
# 3. BIOCLIMATIC PREDICTORS
# -----------------------------------------------------------------------------

# Option A: load the already downloaded present-day WorldClim TIFFs.
# This is preferable for reproducibility than downloading data at runtime.
present_bioclim_dir <- file.path(dir_data_env, "present", "bioclim")

bio_files <- list.files(
  present_bioclim_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

if (length(bio_files) == 0) {
  stop("No present-day bioclimatic .tif files found in: ",
       present_bioclim_dir)
}

bio <- terra::rast(bio_files)

# Crop to study extent. The script supplied an extent of -43/-37 longitude
# and -8/-3 latitude.
bio <- terra::crop(bio, study_extent)

# NOTE: Ensure layers are ordered and named consistently (BIO1–BIO19) before
# selecting variables. Do not rely on alphabetical filenames without checking.
print(names(bio))
plot(bio[[1]])


# -----------------------------------------------------------------------------
# 4. TOPOGRAPHIC PREDICTORS
# -----------------------------------------------------------------------------

# Elevation raster should be stored locally in the repository.
elevation_file <- file.path(dir_data_env, "topography", "elevation.tif")

if (!file.exists(elevation_file)) {
  warning("Elevation raster not found: ", elevation_file,
          "\nSkipping topographic derivation until the file is supplied.")
  elevation <- NULL
  aspect <- NULL
  slope <- NULL
} else {
  elevation <- terra::rast(elevation_file)
  elevation <- terra::crop(elevation, study_extent)

  aspect <- terra::terrain(elevation, v = "aspect", unit = "degrees")
  slope  <- terra::terrain(elevation, v = "slope", unit = "degrees")

  names(elevation) <- "elevation"
  names(aspect) <- "aspect"
  names(slope) <- "slope"

  plot(elevation)
  plot(aspect)
  plot(slope)
}


# -----------------------------------------------------------------------------
# 5. SOIL PREDICTORS
# -----------------------------------------------------------------------------

soil_dir <- file.path(dir_data_env, "soil")

soil_files <- c(
  organic_carbon = "ocd_0-5cm_mean_30s.tif",
  soil_pH        = "phh2o_0-5cm_mean_30s.tif",
  sand           = "sand_0-5cm_mean_30s.tif",
  silt           = "silt_0-5cm_mean_30s.tif"
)

soil_paths <- file.path(soil_dir, soil_files)

if (!all(file.exists(soil_paths))) {
  warning("One or more SoilGrids files are missing. Check: ", soil_dir)
  soil <- NULL
} else {
  soil <- terra::rast(soil_paths)
  names(soil) <- names(soil_files)
  soil <- terra::crop(soil, study_extent)
  plot(soil[[1]], main = "Soil predictor example")
}


# -----------------------------------------------------------------------------
# 6. ALIGNMENT OF ENVIRONMENTAL RASTERS
# -----------------------------------------------------------------------------

# All predictors used together must have matching CRS, resolution, extent,
# and origin. The following uses the bioclimatic raster as the reference grid.
# Bilinear interpolation is suitable for continuous predictors. If categorical
# predictors are added, use nearest-neighbor resampling for those layers.

if (!is.null(elevation)) {
  elevation_aligned <- terra::resample(elevation, bio[[1]], method = "bilinear")
  aspect_aligned    <- terra::resample(aspect, bio[[1]], method = "bilinear")
  slope_aligned     <- terra::resample(slope, bio[[1]], method = "bilinear")
} else {
  elevation_aligned <- aspect_aligned <- slope_aligned <- NULL
}

if (!is.null(soil)) {
  soil_aligned <- terra::resample(soil, bio[[1]], method = "bilinear")
} else {
  soil_aligned <- NULL
}

# Combine layers that are available. Confirm names and predictor set before use.
predictors_all <- bio

if (!is.null(elevation_aligned)) {
  predictors_all <- c(
    predictors_all, elevation_aligned, aspect_aligned, slope_aligned
  )
}

if (!is.null(soil_aligned)) {
  predictors_all <- c(predictors_all, soil_aligned)
}

print(predictors_all)
print(names(predictors_all))


# -----------------------------------------------------------------------------
# 7. EXTRACT ENVIRONMENTAL VALUES AT OCCURRENCES
# -----------------------------------------------------------------------------

occ_xy <- as.matrix(occ[, c("Longitude", "Latitude")])

# terra::extract expects coordinates in the same CRS as the raster.
# Occurrence coordinates in longitude/latitude should be WGS84 (EPSG:4326).
if (terra::crs(predictors_all) != "EPSG:4326") {
  message("Check predictor CRS and occurrence coordinate CRS before extraction.")
}

env_at_occ <- terra::extract(predictors_all, occ_xy)
env_at_occ <- env_at_occ[, -1, drop = FALSE]

occ_env <- cbind(occ, env_at_occ)

# Descriptive statistics for extracted predictors.
print(summary(occ_env))

# Example: detailed summary for a selected predictor, if present.
if ("wc2.1_30s_bio_12" %in% names(occ_env)) {
  print(psych::describe(occ_env[, "wc2.1_30s_bio_12", drop = FALSE]))
}


# -----------------------------------------------------------------------------
# 8. MULTICOLLINEARITY / VIF
# -----------------------------------------------------------------------------

# usdm::vifstep expects a data.frame of predictor values.
# Exclude occurrence columns and any non-predictor fields.
predictor_names <- names(predictors_all)
env_values <- occ_env[, intersect(predictor_names, names(occ_env)), drop = FALSE]
env_values <- env_values[complete.cases(env_values), , drop = FALSE]

if (ncol(env_values) > 1 && nrow(env_values) > ncol(env_values)) {
  vif_result <- usdm::vifstep(env_values, th = 10)
  print(vif_result)

  # Exclude predictors flagged by VIF from the raster stack.
  predictors_vif <- usdm::exclude(predictors_all, vif_result)
  print(names(predictors_vif))
} else {
  warning("Not enough complete occurrence-level data for VIF. ",
          "Review the extraction table and sample size.")
  predictors_vif <- predictors_all
}

# IMPORTANT:
# The original script contains inconsistent predictor names and a variable
# subset that does not match the model object. Confirm the final selected
# predictors against the manuscript and future/past raster layers.
# Do not rename layers merely to force them to match; verify each variable.


# -----------------------------------------------------------------------------
# 9. OPTIONAL EXPLORATORY PCA
# -----------------------------------------------------------------------------

# PCA is exploratory and is not automatically part of the SDM calibration.
# Use complete raster-cell data only if that is the intended analysis.
# This can be memory-intensive for large rasters.

# pca_df <- as.data.frame(predictors_vif, na.rm = TRUE)
# pca_fit <- ade4::dudi.pca(pca_df, scannf = FALSE, nf = 2)
# factoextra::fviz_pca_biplot(pca_fit, col.var = "red", col.ind = "blue")


# -----------------------------------------------------------------------------
# 10. BIOMOD2 FORMATTING AND MODEL CALIBRATION
# -----------------------------------------------------------------------------

if (RUN_MODELING) {

  # Check the exact biomod2 version and model names/options before running.
  # The source script used random pseudo-absences, two PA repetitions, and
  # 500 pseudo-absence points per repetition in this section.
  biomod_data <- BIOMOD_FormatingData(
    resp.var = occ$presence,
    resp.xy = occ[, c("Longitude", "Latitude")],
    expl.var = predictors_vif,
    resp.name = "Atractus_ronnie",
    PA.nb.rep = 2,
    PA.nb.absences = 500,
    PA.strategy = "random"
  )

  # The source script contains several conflicting model lists (GLM/CTA/MAXENT/
  # ANN in one block; other algorithms in later blocks). This version keeps
  # the main model set from the primary calibration block. Verify against the
  # manuscript before execution.
  modeling_options <- bm_ModelingOptions(
    data.type = "binary",
    models = c("GLM", "CTA", "MAXENT", "ANN"),
    strategy = "bigboss",
    bm.format = biomod_data
  )

  models <- BIOMOD_Modeling(
    data = biomod_data,
    modeling.id = "Atractus_ronnie_current",
    models = c("GLM", "CTA", "MAXENT", "ANN"),
    bm.options = modeling_options,
    nb.rep = 3,
    data.split.perc = 70,
    var.import = 3,
    metric.eval = c("TSS", "ROC"),
    do.full.models = FALSE,
    do.progress = TRUE
  )

  # Model evaluation
  model_evaluations <- get_evaluations(models)
  print(model_evaluations)

  bm_PlotEvalMean(
    bm.out = models,
    metric.eval = c("ROC", "TSS"),
    xlim = c(0.5, 1),
    ylim = c(0.5, 1)
  )

  # Variable importance
  model_var_importance <- get_variables_importance(models)
  print(model_var_importance)

  # Save variable importance if writexl is installed.
  if (requireNamespace("writexl", quietly = TRUE)) {
    writexl::write_xlsx(
      as.data.frame(model_var_importance),
      file.path(dir_output, "variable_importance.xlsx")
    )
  }

  # Ensemble modeling
  ensemble_models <- BIOMOD_EnsembleModeling(
    bm.mod = models,
    models.chosen = "all",
    em.by = "PA+run",
    em.algo = "EMmean",
    metric.select = NULL,
    metric.eval = c("TSS", "ROC"),
    var.import = 0
  )

  ensemble_evaluations <- get_evaluations(ensemble_models)
  print(ensemble_evaluations)

  # Current-climate projection
  current_projection <- BIOMOD_Projection(
    bm.mod = models,
    new.env = predictors_vif,
    proj.name = "current",
    models.chosen = "all",
    build.clamping.mask = TRUE
  )

  current_ensemble_projection <- BIOMOD_EnsembleForecasting(
    bm.em = ensemble_models,
    bm.proj = current_projection,
    metric.binary = "TSS"
  )

  current_prediction <- get_predictions(current_ensemble_projection)
  plot(current_prediction)

  terra::writeRaster(
    terra::rast(current_prediction),
    file.path(dir_output, "current_ensemble_prediction.tif"),
    overwrite = TRUE
  )

  saveRDS(models, file.path(dir_output, "biomod2_models.rds"))
  saveRDS(ensemble_models, file.path(dir_output, "biomod2_ensemble.rds"))
}


# -----------------------------------------------------------------------------
# 11. FUTURE CLIMATE PROJECTIONS — TEMPLATE
# -----------------------------------------------------------------------------

if (RUN_PROJECTIONS) {

  # Prepare each future predictor stack separately.
  # Required: same predictor names/order, CRS, resolution, extent and units
  # as the predictors used to calibrate the models.
  #
  # The pasted source contains conflicting future configurations:
  # - MIROC6 vs HadGEM3-GC31-LL;
  # - 2081–2100 vs 2041–2060;
  # - SSP126/245/585 and other inconsistent scenario labels.
  #
  # The manuscript's final configuration should be used here. This section
  # intentionally stops rather than silently choosing among those alternatives.

  stop(
    "Future projections are not activated: first confirm the final GCM, ",
    "time period, SSPs, and predictor subset in the manuscript."
  )

  # Template after confirming scenario inputs:
  #
  # future_predictors <- terra::rast(list.files(
  #   file.path(dir_data_future, "confirmed_scenario"),
  #   pattern = "\\.tif$", full.names = TRUE
  # ))
  #
  # names(future_predictors) <- names(predictors_vif)
  #
  # future_projection <- BIOMOD_Projection(
  #   bm.mod = models,
  #   new.env = future_predictors,
  #   proj.name = "future_scenario",
  #   models.chosen = "all",
  #   build.clamping.mask = TRUE
  # )
  #
  # future_ensemble <- BIOMOD_EnsembleForecasting(
  #   bm.em = ensemble_models,
  #   bm.proj = future_projection,
  #   metric.binary = "TSS"
  # )
}


# -----------------------------------------------------------------------------
# 12. PALEOCLIMATE PROJECTIONS — TEMPLATE
# -----------------------------------------------------------------------------

# The source script contains LGM, MID, and LIG projection blocks, but the
# predictor names and selected variable sets differ from the current model.
# Reuse the same projection pattern as the future section only after confirming
# that paleoclimate predictors contain the exact variables used in calibration.
#
# Suggested input folders:
# data/climate_scenarios/past/LGM/
# data/climate_scenarios/past/MID/
# data/climate_scenarios/past/LIG/


# -----------------------------------------------------------------------------
# 13. THRESHOLDING AND AREA CALCULATION — NOTES
# -----------------------------------------------------------------------------

# The source script uses more than one thresholding approach:
# (a) normalization to 0–1 followed by a 0.5 threshold;
# (b) a biomod2 ensemble TSS cutoff.
# These are not interchangeable. Use the threshold defined in the manuscript.

# For geographic area, do not multiply cell count by a fixed km² value unless
# the raster is equal-area and the cell area is verified. For geographic
# rasters, cell area varies with latitude. Use terra::cellSize() instead.
#
# Example, once a binary raster has been generated:
#
# binary_raster <- terra::rast(file.path(dir_output, "binary_current.tif"))
# area_per_cell <- terra::cellSize(binary_raster, unit = "km")
# total_area_km2 <- terra::global(
#   area_per_cell * (binary_raster == 1),
#   fun = "sum",
#   na.rm = TRUE
# )
# print(total_area_km2)


# -----------------------------------------------------------------------------
# 14. EXPORT FIGURES
# -----------------------------------------------------------------------------

# Example high-resolution raster plot:
#
# png(
#   filename = file.path(dir_output, "current_suitability.png"),
#   width = 10, height = 8, units = "in", res = 600
# )
# plot(current_prediction)
# dev.off()


# -----------------------------------------------------------------------------
# 15. SESSION INFORMATION
# -----------------------------------------------------------------------------

# Save this after running the finalized workflow to document package versions:
# writeLines(capture.output(sessionInfo()),
#            file.path(dir_output, "sessionInfo.txt"))
