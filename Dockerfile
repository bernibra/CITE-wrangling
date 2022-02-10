# R 4.1.2
FROM rocker/tidyverse:4.1.2

# Install R packages
RUN apt-get update \
  && apt-get -y --no-install-recommends install libudunits2-dev libgeos-dev libgeos++-dev libgdal-dev libproj-dev libudunits2-dev libgdal-dev libv8-dev
RUN R -e "options(repos = \
  list(CRAN = 'https://mran.revolutionanalytics.com/snapshot/${WHEN}')); \
  install.packages(c('BiocManager'))"

ENV USER rstudio
