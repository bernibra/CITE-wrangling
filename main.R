# Prepare workspace --------------------------------------------------------

pkgconfig::set_config("strings_in_dots" = "literals")

# Load libraries

library(magrittr, quietly = T)
library(drake, quietly = T)
library(purrr, quietly = T)
library(dplyr, quietly = T)
library(SingleCellExperiment, quietly = T)

f <- lapply(list.files("code", full.names = T), source)

# Configuration -----------------------------------------------------------

Sys.setenv(VROOM_CONNECTION_SIZE = "5000000")
options(timeout = 3600)

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  metadata = yaml::read_yaml(file_in("./data/metadata.yalm")),
  datasets = yaml::read_yaml(file_in("./data/database.yalm")),
  data_download_date = config$raw_data_retrieved,
  geo_download_key = metadata$GEO_download_key
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
                        download_date = data_download_date),
  geo_raw_rna = get_raw_GEO(ids = geo_meta,
                                dest_dir = "data/raw",
                                ftype = "rna",
                                download_date = data_download_date,
                                rmfile=FALSE) # You shouldn't run this in your local machine
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
dir.create("data/processed/rna-data", showWarnings = FALSE)
dir.create("data/processed/names", showWarnings = FALSE)
dir.create("data/processed/names/protein", showWarnings = FALSE)
dir.create("data/processed/names/rna", showWarnings = FALSE)

raw_to_SingleCellExperiment <- drake_plan(
  geo_sce_protein = load_geo(paths = geo_raw_protein, 
                     ids = geo_download_key,
                     info = datasets,
                     ftype ="protein"),
  geo_sce_rna = load_geo(paths = geo_raw_rna, 
                     ids = geo_download_key,
                     info = datasets,
                     ftype ="rna",
                     rmfile=FALSE) # You shouldn't run this in your local machine
)

build_protein_dictionary <- drake_plan(
  protein_db = unify_names(paths = geo_sce_protein)
)

process_data_plan <- rbind(
  raw_to_SingleCellExperiment,
  build_protein_dictionary
)

# Project workflow --------------------------------------------------------

project_plan <- rbind(
  configuration_plan,
  get_data_plan,
  process_data_plan
  )

make(project_plan, lock_envir = FALSE)
