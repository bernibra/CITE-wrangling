# Prepare workspace -------------------------------------------------------

pkgconfig::set_config("strings_in_dots" = "literals")

# Load libraries

library(magrittr, quietly = T)
library(drake, quietly = T)
library(purrr, quietly = T)
library(dplyr, quietly = T)
library(SingleCellExperiment, quietly = T)

f <- lapply(list.files("code", full.names = T), source)

# Any arguments? ----------------------------------------------------------
# If there aren't arguments, the pipeline will work for all datasets
# args = commandArgs(trailingOnly=TRUE)

done <- c(19, 7, 18, 14, 10, 16, 23, 24, 22, 13, 12, 20, 15, 25, 11, 9)
too_long <- c(21, 8)
args <- 9
if(length(args)==0) args <- NULL else args <- args[1]

# Configuration -----------------------------------------------------------un

Sys.setenv(VROOM_CONNECTION_SIZE = "5000000")
options(timeout = 3600)

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  data = lapply(list.files(file_in("data/databases/"), full.names = T), function(x) yaml::read_yaml(x)),
  metadata = sapply(data, function(x) setNames(list(x$download), x$metadata$doi), USE.NAMES = F),
  datasets = sapply(data, function(x) setNames(list(x$load), x$download$id), USE.NAMES = F),
  data_download_date = config$raw_data_retrieved,
  download_key = metadata
)

# Download data ----------------------------------------------------------

# create download dir if not already there
dir.create("data/raw", showWarnings = FALSE)

# Download data
get_raw_db <- drake_plan(
  raw_protein = get_raw(ids = download_key,
                    dest_dir = "data/raw",
                    ftype = "protein",
                    download_date = data_download_date,
                    args=args)
  # raw_rna = get_raw(ids = download_key,
  #                   dest_dir = "data/raw",
  #                   ftype = "rna",
  #                   download_date = data_download_date,
  #                   rmfile=FALSE,
  #                   args=args) # You shouldn't run this in your local machine
)

get_data_plan <- rbind(
  get_raw_db
)

# Processing data --------------------------------------------------------

# Add main directories for processed data
dir.create("data/processed", showWarnings = FALSE)
dir.create("data/processed/protein-data", showWarnings = FALSE)
dir.create("data/processed/rna-data", showWarnings = FALSE)
dir.create("data/processed/names", showWarnings = FALSE)
dir.create("data/processed/names/protein", showWarnings = FALSE)
dir.create("data/processed/names/rna", showWarnings = FALSE)

raw_to_SingleCellExperiment <- drake_plan(
  sce_protein = load_db(paths = raw_protein,
                     ids = download_key,
                     database = datasets,
                     ftype ="protein")
  # sce_rna = load_db(paths = raw_rna,
  #                    ids = download_key,
  #                    database = datasets,
  #                    ftype ="rna",
  #                    rmfile=FALSE), # You shouldn't run this in your local machine
)

build_protein_dictionary <- drake_plan(
  sce_protein_merged = merge_samples(paths = raw_protein,
                                     files = sce_protein$rds,
                                     metadata = metadata, 
                                     database = datasets,
                                     ftype = "protein",
                                     overwrite = TRUE)
  # protein_normalized = normalize_protein(paths = sce_protein$names, type="default"),
  # protein_db = unify_names(paths = sce_protein$names),
  #protein_lists = reformat_protein(pnames = protein_db, ids = datasets)
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
