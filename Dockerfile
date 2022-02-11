# R 4.1.2
FROM rocker/tidyverse:4.1.2

# Install R packages
RUN apt-get update \
  && apt-get -y --no-install-recommends install libudunits2-dev libgeos-dev libgeos++-dev libgdal-dev libproj-dev libudunits2-dev libgdal-dev libv8-dev

RUN R -e "install.packages(c('BiocManager', 'drake', 'purrr'), repos = c(CRAN = 'https://mran.revolutionanalytics.com/snapshot/2022-02-01'))"

RUN R -e "BiocManager::install(c('SingleCellExperiment', 'GEOquery'), version = BiocManager::version())"

ENV USER rstudio
