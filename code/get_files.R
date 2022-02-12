# Download raw data for one GEO dataset
get_file <- function(id, dest_dir, download_date = NULL){
  rdir <- file.path(dest_dir, id)
  if(!file.exists(file.path(rdir, id))){
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading data on ", download_date)
    GEOquery::getGEO(id, destdir = rdir)
  } else {
    message("file already found")
    return(0)
  }
}

get_files <- function(ids, dest_dir, download_date = NULL){
  lapply(ids, function(id) get_file(id=id, dest_dir = dest_dir, download_date = download_date))
}
