################################################
# Set of methods to download raw data
################################################

# Set methods
setup_download <- function(path) UseMethod("setup_download")
download_raw <- function(rdir) UseMethod("download_raw")

# Create directories if not there
setup_download.default <- function(path, ...){
  # Create main directory if not there
  dir.create(path, showWarnings = FALSE)
  
  return(0)
}

# Download metadata for geo libraries
setup_download.geo <- function(path, ...){
  if(!file.exists(path)){
    
    # Create dir if not there
    dir.create(path, showWarnings = FALSE)
    message("donwloading data on ", download_date)
    
    # Download metadata
    GEOquery::getGEO(id, destdir = path)
    
  } else {
    
    message("---> file already found: ", id)
    
  }
  return(0)
}

# direct download with link
download_raw.default <- function(rdir, ...){
  return(0)
}

# direct download with link
download_raw.wget <- function(rdir, ...){

  # This definition is useful to know what path to return
  experiments <- id$id
  
  # Try to use the link directly if available
  if (!is.null(id$wlink[[ftype]])){
    
    for(k in 1:length(id$wlink[[ftype]])){
      
      # Create directory as GEOquery
      if(length(id$wlink[[ftype]])>1){
        experiments_ <- file.path(rdir, paste(experiments, k, sep="_"))
      }else{
        experiments_ <- file.path(rdir, experiments)
      }
      dir.create(experiments_, showWarnings = FALSE)
      
      # Download links
      download.file(url = id$wlink[[ftype]][k], destfile = file.path(experiments_, id$fname[[ftype]][k]))
      
      # Just ensure that we didn't create an empty directory
      if (length(list.files(experiments_))==0){unlink(rdir, recursive = T)}
    }
  }
  
  # Return directories if not empty
  if (!(length(list.files(rdir))==0)) {
    return(list.files(rdir, recursive = T, full.names = T))
  }else{
    return(0)
  }
 
}

# Well formatted geo database
download_raw.geo <- function(rdir, ...){
  
  # Find relevant supplementary files
  experiments <- set_names(list.files(basedir, full.names = T,pattern = "\\.txt.gz$"))%>%
    map(function(x) GEOquery::getGEO(filename = x)) %>%
    map(Biobase::pData)  %>%
    bind_rows() %>%
    mutate(data_processing_lowercase = tolower(!!sym(id$description))) %>%
    filter(stringr::str_detect(data_processing_lowercase, id$keyword[[ftype]])) %>%
    pull("geo_accession")
  
  # Download raw data
  experiments %>%
    map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
  
  
  # Was the data downloaded or is the new directory empty?
  if (length(list.files(rdir))==0){
    # This definition is useful to know what path to return
    experiments <- id$id
    experiments %>% map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
  }
  
  # Return directories if not empty
  if (!(length(list.files(rdir))==0)) {
    return(paste(rdir, experiments, sep="/"))
  }else{
    return(0)
  }
  
}