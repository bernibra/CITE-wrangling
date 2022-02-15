# Prepare workspace --------------------------------------------------------

pkgconfig::set_config("strings_in_dots" = "literals")

# Load libraries

library(magrittr)
library(drake)
library(purrr)
library(dplyr)

f <- lapply(list.files("code", full.names = T), source)

# Configuration -----------------------------------------------------------

Sys.setenv(VROOM_CONNECTION_SIZE = "500000")

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
                    dest_dir = file_out("data/raw"),
                    download_date = data_download_date),
  geo_raw = get_raw_GEO(ids = geo_meta, 
                        dest_dir = "data/raw")
)

get_data_plan <- rbind(
  get_GEOquery_raw
)

# Processing data --------------------------------------------------------


# Project workflow --------------------------------------------------------

project_plan <- rbind(
  configuration_plan,
  get_data_plan
  )

make(project_plan, lock_envir = FALSE)
