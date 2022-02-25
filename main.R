# Prepare workspace --------------------------------------------------------

pkgconfig::set_config("strings_in_dots" = "literals")

# Load libraries

library(magrittr)
library(drake)
library(purrr)
library(dplyr)
library(SingleCellExperiment)

f <- lapply(list.files("code", full.names = T), source)

# Configuration -----------------------------------------------------------

Sys.setenv(VROOM_CONNECTION_SIZE = "5000000")
options(timeout = 3600)

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  datasets = yaml::read_yaml(file_in("./data/database.yalm")),
  data_download_date = config$raw_data_retrieved,
  geo_download_key = datasets$GEO_download_key
)

# Download data ----------------------------------------------------------

# create download dir if not already there
dir.create("data/raw", showWarnings = FALSE)

# Download GEOquery data
get_GEOquery_raw <- drake_plan(
  geo_meta = get_metadata_GEO(ids = geo_download_key, 
                    dest_dir = "data/raw",
                    download_date = data_download_date),
  geo_raw_protein = get_raw_GEO(ids = geo_meta, 
                        dest_dir = "data/raw",
                        ftype = "protein",
                        download_date = data_download_date)
)

# get_figshare_raw <- drake_plan(
# )

# get_10Gen_raw <- drake_plan(
# )

# get_ebi_raw <- drake_plan(
# )

# get_fredhutch_raw <- drake_plan(
# )

get_data_plan <- rbind(
  get_GEOquery_raw
)

# Processing data --------------------------------------------------------

dir.create("data/processed", showWarnings = FALSE)
dir.create("data/processed/protein-data", showWarnings = FALSE)
dir.create("data/processed/names", showWarnings = FALSE)
dir.create("data/processed/names/protein", showWarnings = FALSE)
dir.create("data/processed/names/rna", showWarnings = FALSE)

Raw_to_SingleCellExperiment <- drake_plan(
  geo_sce_protein = load_geo(paths = geo_raw_protein, 
                     ids = geo_download_key,
                     ftype ="protein")
  # protein_db = unify_names(geo_sce)
)

# build_protein_dictionary <- drake_plan(
#   
# )

process_data_plan <- rbind(
  Raw_to_SingleCellExperiment
)

# Project workflow --------------------------------------------------------

project_plan <- rbind(
  configuration_plan,
  get_data_plan,
  process_data_plan
  )

make(project_plan, lock_envir = FALSE)
