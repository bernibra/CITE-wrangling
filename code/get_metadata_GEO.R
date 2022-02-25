# Download metadata data for one GEO dataset
get_metadata <- function(id, dest_dir, download_date = NULL){
  
  # Define destination
  rdir <- file.path(dest_dir, id)
  print(rdir)
  
  if(!file.exists(rdir)){
    
    # Create dir if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading data on ", download_date)
    
    print(id)
    # Download metadata
    GEOquery::getGEO(id, destdir = rdir)

  } else {

    message("---> file already found: ", id)
    return(0)
    
  }
}

get_metadata_GEO <- function(ids, dest_dir, download_date = NULL){
  
  # Loop over ids to get metadata
  lapply(ids, function(id) get_metadata(id=id$id, dest_dir = dest_dir, download_date = download_date))
  
  return(ids)

}
