# Semifossorial-Snakes-SDMs

Occurrence records, environmental predictors, R scripts, and
phylogenetic data used for ecological niche modeling and phylogenetic
analyses of *Atractus ronnie* under past, present, and future climate
scenarios.

# Ecological Niche Modeling and Phylogenetic Analyses of *Atractus ronnie*

## Overview

This repository provides data and reproducible R workflows associated
with the study of *Atractus ronnie*, a microendemic semi-fossorial snake
from the Brejos de Altitude of Ceará, northeastern Brazil. The project
combines ecological niche modeling (ENM), climate projections,
land-use/deforestation analysis, and phylogenetic inference to
investigate the species' distribution and conservation vulnerability.

The repository is intended to make the data-processing and analytical
workflow transparent and reproducible. Scripts should be run in sequence
after updating the file paths and confirming that the required input
data are available.

## Associated manuscript

**When refugia become traps: climate change and extinction risk in a
microendemic semi-fossorial snake**

Authors: \[Add the final author list\]

Journal: \[Add journal and publication status\]

DOI: \[Add DOI when available\]

## Repository contents

``` text
├── data/
│   ├── occurrence_records/
│   ├── environmental_predictors/
│   ├── phylogenetic_data/
│   ├── climate_scenarios/
│   └── deforestation/
├── scripts/
│   ├── 01_occurrence_data_processing.R
│   ├── 02_environmental_predictors_and_VIF.R
│   ├── 03_current_SDM_and_ensemble.R
│   ├── 04_future_projections.R
│   ├── 05_past_projections.R
│   ├── 06_EAOO_and_land_use_analysis.R
│   └── 07_phylogenetic_analysis.R
├── outputs/
│   ├── suitability_maps/
│   ├── binary_maps/
│   ├── evaluation_metrics/
│   ├── phylogenetic_trees/
│   └── tables/
├── LICENSE
├── CITATION.cff
└── README.md
```

*This is a suggested repository structure. Update it to reflect the
files actually committed to the repository.*

## Study area and occurrence records

Occurrence records were compiled from published sources and biodiversity
databases, including GBIF. The working dataset described in the
manuscript contained 58 records. Spatial thinning with **spThin** using
a 2-km thinning distance yielded 17 spatially independent records.

The repository should include the occurrence table and metadata
documenting the source of each record, coordinate uncertainty, filtering
decisions, and any restrictions on reuse. Do not publish sensitive
locality information if its release could threaten the species or
violate data-provider conditions.

## Environmental predictors

The workflow uses climatic, topographic, and soil predictors.

### Climate

Bioclimatic variables were obtained from WorldClim. The original R
script includes a WorldClim resolution setting of 0.5 arc-minutes and a
geographic study extent of approximately:

-   Longitude: −43 to −37°
-   Latitude: −8 to −3°

### Topography

Topographic predictors include elevation, aspect, and slope. Aspect and
slope were derived from elevation data using terrain-analysis functions.

### Soil

The script includes SoilGrids layers for the 0--5 cm soil depth:

-   Organic carbon (`ocd`)
-   pH in water (`phh2o`)
-   Sand
-   Silt

The predictor-selection workflow should document the final retained
variables and the VIF threshold used. The original script contains
several inconsistent variable names and selection vectors; the final
predictor list should be verified against the actual modeling object and
manuscript before publication.

## Modeling workflow

The R scripts are intended to document the following stages:

1.  Import and inspect occurrence records.
2.  Prepare and crop environmental predictor layers.
3.  Derive topographic predictors and prepare soil layers.
4.  Harmonize predictor layers (CRS, resolution, extent, and grid
    alignment).
5.  Extract environmental values at occurrence locations.
6.  Evaluate multicollinearity and select predictors.
7.  Format occurrence and pseudo-absence data for **biomod2**.
8.  Calibrate individual models and evaluate model performance.
9.  Build ensemble models and project current suitability.
10. Project suitability under past and future climate scenarios.
11. Apply thresholds and calculate suitable-area metrics.
12. Conduct phylogenetic analyses using the deposited sequence
    alignments and metadata.

The scripts and manuscript should be checked together before release.
The working script includes exploratory code, alternative modeling
configurations, and incomplete code fragments. These should not be
interpreted as a single fully reproducible pipeline until the final
inputs, predictor sets, model algorithms, thresholds, and scenario
settings have been confirmed.

## Climate scenarios

The manuscript and project workflow include paleoclimate and future
projections. The repository should identify the exact climate model,
time period, scenario, variable set, resolution, and source files used
for each projection.

The working script contains references to LGM, MID, and LIG paleoclimate
layers, as well as future SSP projections. Some code fragments use
different climate models, periods, SSPs, and variable subsets. The final
README and scripts must reflect the scenarios actually used in the
published analyses rather than all exploratory code.

## Phylogenetic data

The phylogenetic-data directory should contain, where applicable:

-   DNA sequences in FASTA format;
-   aligned sequence matrices (FASTA or NEXUS);
-   sequence accession numbers;
-   specimen/voucher metadata;
-   taxon sampling and GenBank source information;
-   phylogenetic trees and analysis files;
-   software versions and inference settings.

New sequence accession numbers should be added once they are assigned by
GenBank. Replace any temporary accession placeholders before
publication.

## Software

The workflow was developed in R. Packages referenced in the working
scripts include:

-   `biomod2`
-   `ecospat`
-   `terra`
-   `raster`
-   `geodata`
-   `spThin`
-   `usdm`
-   `sf`
-   `ggplot2`
-   `tidyterra`
-   `ade4`
-   `psych`
-   `factoextra`
-   `patchwork`
-   `writexl`

Package versions and the R version should be recorded in a
reproducibility file (for example, `renv.lock` or `sessionInfo.txt`)
once the final scripts have been tested.

## Data availability

The repository will provide the data and scripts necessary to reproduce
the analyses, subject to data-provider licenses and
conservation-sensitive locality restrictions.

Large raster files and model outputs may exceed GitHub's file-size
limits. Consider depositing large files in Zenodo or another repository
that provides a persistent DOI, and link to those files from this
repository.

## Citation

If you use the data or scripts, please cite the associated manuscript:

\[Insert the final citation here.\]

A `CITATION.cff` file should be added after the author list, publication
details, and DOI are finalized.

## License

The repository currently displays the MIT License. Confirm that this
license is appropriate for all deposited scripts and data. Data obtained
from external repositories may remain subject to their original licenses
and terms of use.

## Contact

Átilas Rodrigues de Sousa\
Federal University of Ceará (UFC), Brazil\
Email: atilasrodrigues28@alu.ufc.br
