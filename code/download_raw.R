################################################
# Set of methods to download raw data
################################################

# Set methods
setup_download <- function(path, id, download_date, ...) UseMethod("setup_download", path)
download_raw <- function(rdir, basedir, id, ftype, ...) UseMethod("download_raw", rdir)

# Create directories if not there
setup_download.default <- function(path, id, download_date, ...){
  # Create main directory if not there
  dir.create(path, showWarnings = FALSE)
  
  return(0)
}

# Download metadata for geo libraries
setup_download.geo <- function(path, id, download_date, ...){
  if(!file.exists(path)){

    # Create dir if not there
    dir.create(path, showWarnings = FALSE)
    message("downloading data on ", download_date)

    # Download metadata
    GEOquery::getGEO(id, destdir = path)

  } else {

    message("---> file already found: ", id)

  }
  return(0)
}

# direct download with link
download_raw.default <- function(rdir, basedir, id, ftype, ...){
  return(0)
}

# direct download with link
download_raw.impossible <- function(rdir, basedir, id, ftype, ...){
  
  # This definition is useful to know what path to return
  experiments <- id$id
  
  # Create subdirectory
  dir.create(file.path(rdir, experiments), showWarnings = FALSE)
  
  write(paste0(
    "The files can be downloaded using the following link:\n", id$source, "\n\n",
    "Every file should be added to its corresponsing directory. That is, `./supp_rna/",experiments,
    "` for RNA data, `./supp_protein/",experiments,
    "` for protein data, `./supp_hto/",experiments, "` for hto data, and `./metadata` for the additional files\n",
    "The files that should be added are the following:\n",
    paste(id$fname[["other"]], collapse = "\n"),
    "\n\ncomments: ", id$comments
  ), file=file.path(basedir, "README.txt"))
  
  return(list.files(rdir, full.names = T))
}

# direct download with link
download_raw.wget <- function(rdir, basedir, id, ftype, ...){

  # This definition is useful to know what path to return
  experiments <- id$id
  
  # Try to use the link directly if available
  if (!is.null(id$wlink[[ftype]])){
    
    # Create subdirectory
    if (is.null(id$fgroup[[ftype]])){
      dir.create(file.path(rdir, experiments), showWarnings = FALSE)
      
      for(k in 1:length(id$wlink[[ftype]])){
        # Download links
        download.file(url = id$wlink[[ftype]][k], destfile = file.path(rdir, experiments, id$fname[[ftype]][k]))
      }
      # Just ensure that we didn't create an empty directory
      if (length(list.files(file.path(rdir, experiments)))==0){unlink(rdir, recursive = T)}
      
    }else{
      for(k in 1:length(id$wlink[[ftype]])){
        # Create subdirectory
        dir.create(file.path(rdir, paste(experiments, id$fgroup[[ftype]][k],sep="_")), showWarnings = FALSE)
          
        # Download links
        download.file(url = id$wlink[[ftype]][k], destfile = file.path(rdir, paste(experiments, id$fgroup[[ftype]][k],sep="_"), id$fname[[ftype]][k]))
        
        # Just ensure that we didn't create an empty sub-directory
        if (length(list.files(file.path(rdir, paste(experiments, id$fgroup[[ftype]][k],sep="_"))))==0){
          unlink(file.path(rdir, paste(experiments, id$fgroup[[ftype]][k],sep="_")), recursive = T)
        }
      }
      # Just ensure that we didn't create an empty directory
      if (length(list.dirs(rdir, recursive = F))==0){unlink(rdir, recursive = T)}
    }
  }

  # Return directories if not empty
  if (!(length(list.files(rdir))==0)) {
    return(list.files(rdir, full.names = T))
  }else{
    return(0)
  }
}

# direct download with link
download_raw.metadata <- function(rdir, basedir, id, ftype, ...){
  
  # Try to use the link directly if available
  if (!is.null(id$fname[[ftype]])){
    dir.create(file.path(rdir, "metadata"), showWarnings = FALSE)
  }
  
  # Try to use the link directly if available
  if (!is.null(id$wlink[[ftype]])){

    for(k in 1:length(id$wlink[[ftype]])){
      # Define file name
      fname <- file.path(rdir, "metadata", id$fname[[ftype]][k])
      
      # Download files if not there already
      if(!file.exists(fname) & !file.exists(gsub("\\.gz", "", fname))){
        download.file(url = id$wlink[[ftype]][k], destfile = fname)
      }
    }
  }
  return(0)
}

# Well formatted geo database
download_raw.geo <- function(rdir, basedir, id, ftype, ...){
  
  # Find relevant supplementary files
  experiments <- set_names(list.files(basedir, full.names = T,pattern = "\\.txt.gz$"))%>%
    purrr::map(function(x) GEOquery::getGEO(filename = x)) %>%
    purrr::map(Biobase::pData)  %>%
    bind_rows() %>%
    mutate(data_processing_lowercase = tolower(!!sym(id$description))) %>%
    filter(stringr::str_detect(data_processing_lowercase, id$keyword[[ftype]])) %>%
    pull("geo_accession")
  
  # Download raw data
  experiments %>%
    purrr::map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
  
  
  # Was the data downloaded or is the new directory empty?
  if (length(list.files(rdir))==0){
    # This definition is useful to know what path to return
    experiments <- id$id
    experiments %>% purrr::map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
  }
  
  # Return directories if not empty
  if (!(length(list.files(rdir))==0)) {
    return(paste(rdir, experiments, sep="/"))
  }else{
    return(0)
  }
}

# Well formatted geo database
download_raw.array <- function(rdir, basedir, id, ftype, ...){
  
  # This definition is useful to know what path to return
  experiments <- id$id
  
  # Create subdirectory
  dir.create(file.path(rdir, experiments), showWarnings = FALSE)
  
  # Download files
  ArrayExpress::getAE(id$id, path = file.path(rdir, experiments), type = "full", extract = TRUE)
  
  # Filter files that aren't relevant
  files <- list.files(path=file.path(rdir, experiments), full.names = F)
  files <- paste(file.path(rdir, experiments), files[!grepl(pattern = id$keyword[[ftype]], x = files)], sep="/")
  file.remove(files)
  
  # Return directories if not empty
  if (!(length(list.files(rdir))==0)) {
    return(list.files(rdir, full.names = T))
  }else{
    return(0)
  }
  
}