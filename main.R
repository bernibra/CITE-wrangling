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
args_ = commandArgs(trailingOnly=TRUE)

#args_ <- c("Triana2022")

if(length(args_)==0) args_ <- "NULL" else args_ <- args_[1]

# Configuration -----------------------------------------------------------un

Sys.setenv(VROOM_CONNECTION_SIZE = "5000000")
options(timeout = 20000)

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  data = lapply(list.files(file_in("data/databases/"), full.names = T), function(x) yaml::read_yaml(x)),
  download_data = sapply(data, function(x) setNames(list(x$download), x$metadata$doi), USE.NAMES = F),
  load_data = sapply(data, function(x) setNames(list(x$load), x$download$id), USE.NAMES = F),
  metadata = sapply(data, function(x) setNames(list(x$metadata), x$download$id), USE.NAMES = F),
  data_download_date = config$raw_data_retrieved,
  RAMlimit=config$RAMlimit,
  download_key = download_data,
  write.table(x = do.call(rbind.data.frame, lapply(names(metadata), function(x) list(id=x, alias=metadata[[x]]$alias, doi=metadata[[x]]$doi))), 
              file = "data/list-of-papers__tmp.csv", row.names = F, col.names = T),
  db_ids = sapply(data, function(x) x$download$id, USE.NAMES = F),
  args = if(length(which(db_ids==args_))==1) which(db_ids==args_)[[1]] else{ NULL} 
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
                    args=args),
  raw_rna = get_raw(ids = download_key,
                    dest_dir = "data/raw",
                    ftype = "rna",
                    download_date = raw_protein,
                    rmfile=FALSE,
                    args=args),
  raw_hto = get_raw(ids = download_key,
                    dest_dir = "data/raw",
                    ftype = "hto",
                    download_date = raw_rna,
                    rmfile=FALSE,
                    args=args)
)

get_data_plan <- rbind(
  get_raw_db
)

# Processing data --------------------------------------------------------

# Add main directories for processed data
dir.create("data/processed", showWarnings = FALSE)
dir.create("data/processed/sce-objects", showWarnings = FALSE)
dir.create("data/processed/names", showWarnings = FALSE)
dir.create("data/processed/names/protein", showWarnings = FALSE)
dir.create("data/processed/names/rna", showWarnings = FALSE)
dir.create("data/processed/names/hto", showWarnings = FALSE)

# Read files and turn into SCE
raw_to_SingleCellExperiment <- drake_plan(
  sce_protein = load_db(paths = raw_protein,
                     ids = download_key,
                     database = load_data,
                     ftype ="protein",
                     RAMlimit=RAMlimit),
  sce_rna = load_db(paths = raw_rna,
                     ids = download_key,
                     database = load_data,
                     ftype ="rna",
                     rmfile=FALSE,
                     RAMlimit=RAMlimit),
  sce_hto = load_db(paths = raw_hto,
                    ids = download_key,
                    database = load_data,
                    ftype ="hto",
                    rmfile=FALSE,
                    RAMlimit=RAMlimit)
)

# Merge samples if needed
merge_samples_sce <- drake_plan(
  sce_protein_merged = merge_samples(files = sce_protein,
                                     metadata = download_data, 
                                     database = load_data,
                                     ftype = "protein",
                                     overwrite = TRUE),
  sce_rna_merged = merge_samples(files = sce_rna,
                                     metadata = download_data,
                                     database = load_data,
                                     ftype = "rna",
                                     overwrite = TRUE),
  sce_hto_merged = merge_samples(files = sce_hto,
                                     metadata = download_data, 
                                     database = load_data,
                                     ftype = "hto",
                                     overwrite = TRUE)
)

# Add metadata to each file independently. We will probably change that in the future
add_metadata_to_sce <- drake_plan(
  sce_protein_processed=add_metadata(filenames = sce_protein_merged,
                                       metadata=metadata),
  sce_rna_processed=add_metadata(filenames = sce_rna_merged,
                                      metadata=metadata),
  sce_hto_processed=add_metadata(filenames = sce_hto_merged,
                                      metadata=metadata)
)


# build_protein_dictionary <- drake_plan(
#   protein_normalized = normalize_protein(paths = sce_protein$names, type="default"),
#   protein_db = unify_names(paths = sce_protein$names),
#   protein_lists = reformat_protein(pnames = protein_db, ids = datasets)
# )

process_data_plan <- rbind(
  raw_to_SingleCellExperiment,
  merge_samples_sce,
  add_metadata_to_sce#,
  # build_protein_dictionary
)

# Project workflow --------------------------------------------------------

project_plan <- rbind(
  configuration_plan,
  get_data_plan,
  process_data_plan
  )

make(project_plan, lock_envir = F)

warnings()
