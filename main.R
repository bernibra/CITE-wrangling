# Prepare workspace

pkgconfig::set_config("strings_in_dots" = "literals")
library(magrittr)
library(drake)

# Load libraries

f <- lapply(list.files("code", full.names = T), source)


# Configuration -----------------------------------------------------------

configuration_plan <- drake_plan(
  config = yaml::read_yaml(file_in("config.yaml")),
  data_download_date = config$raw_data_retrieved
)

# Download data ----------------------------------------------------------

# create download dir if not already there
dir.create("data/raw", showWarnings = FALSE)

