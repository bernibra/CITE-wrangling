# R 4.1.2
FROM rocker/tidyverse:4.1.2

# Install R packages
RUN apt-get update \
  && apt-get -y --no-install-recommends install libudunits2-dev libgeos-dev libgeos++-dev libgdal-dev libproj-dev libudunits2-dev libgdal-dev libv8-dev libhdf5-serial-dev

RUN R -e "install.packages(c('BiocManager', 'drake', 'purrr', 'Seurat', 'hdf5r', 'memuse'), repos = c(CRAN = 'https://mran.revolutionanalytics.com/snapshot/2022-02-01'))"

RUN R -e "BiocManager::install(c('SingleCellExperiment', 'GEOquery', 'DelayedArray', 'HDF5Array', 'ArrayExpress'), version = BiocManager::version())"

#RUN R -e "reticulate::install_miniconda(); reticulate::py_install('scanpy')"

## This might be a problem...
#ENV USER rstudio

## I might try to run this if I have conflicts between host uid and docker uid
#RUN chmod a+rwx -R CITE-wrangling/smarty.cache.dir
