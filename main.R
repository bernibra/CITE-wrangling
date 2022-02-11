# Prepare workspace

pkgconfig::set_config("strings_in_dots" = "literals")
library(magrittr)
library(drake)

# Load libraries

f <- lapply(list.files("code", full.names = T), source)

# Configuration -----------------------------------------------------------

Sys.setenv(VROOM_CONNECTION_SIZE = "500000")

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  data_download_date = config$raw_data_retrieved,
  geo_download_key = config$GEO_download_key
)

# Download data ----------------------------------------------------------

# create download dir if not already there
dir.create("data/raw", showWarnings = FALSE)

get_GEOquery_raw <- drake_plan(
  geo_db = get_file(id = "GSE152469", 
                    dest_dir = "data/raw",
                    download_date = data_download_date)
)

get_data_plan <- rbind(
  get_GEOquery_raw
)

# Processing data --------------------------------------------------------


# Project workflow

project_plan <- rbind(
  # full_plan,
  configuration_plan,
  get_data_plan
  )

make(project_plan, lock_envir = FALSE)
