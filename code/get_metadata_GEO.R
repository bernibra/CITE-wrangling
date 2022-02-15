# Download metadata data for one GEO dataset
get_metadata <- function(id, dest_dir, download_date = NULL){
  rdir <- file.path(dest_dir, id)
  if(!file.exists(rdir)){
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading data on ", download_date)
    GEOquery::getGEO(id, destdir = rdir)
  } else {
    message("file already found")
    return(0)
  }
}

get_metadata_GEO <- function(ids, dest_dir, download_date = NULL){
  lapply(ids, function(id) get_metadata(id=id$id, dest_dir = dest_dir, download_date = download_date))
  return(ids)
}
