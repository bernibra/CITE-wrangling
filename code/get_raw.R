# Download raw files that contain CITE info for one dataset
get_db <- function(id, dest_dir, ftype="protein", download_date=NULL){
  
  # Setup download
  basedir <- file.path(dest_dir, id$id)
  setup_download(path=structure(basedir, class=id$setup), id=id$id, download_date=download_date)
  
  # Download metadata if not there already
  download_raw(rdir=structure(basedir, class="metadata"), basedir=basedir, id=id, ftype="other")
  
  # Quick check
  possible_types <- c("rna", "protein")
  if(!(ftype %in% possible_types)){
    stop("Wha'choo talkin' 'bout, Willis?")
  }
  
  # Define file paths
  rdir <- file.path(basedir, paste("supp", ftype, sep="_"))
  rdir_ <- file.path(basedir, paste("supp", possible_types[!(possible_types %in% ftype)], sep="_"))
  
  if((!file.exists(rdir))){
    
    # Avoid downloading the same data twice
    if (file.exists(rdir_) & is.null(id$keyword[[ftype]]) & is.null(id$wget[[ftype]]) & is.null(id$fname[[ftype]])){
      R.utils::createLink(link=rdir, target=rdir_)
      message("---> raw files already found: ", id$id)
      return(list.files(rdir, full.names = T))
    }
    
    # Create directory if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data")
    
    experiments <- download_raw(rdir=structure(rdir, class=id$download), basedir=basedir, id=id, ftype=ftype)
    
    # Just ensure that we didn't create an empty directory
    if (length(list.files(rdir))==0){unlink(rdir, recursive = T)}
    
    # Return directories if not empty
    if (!(length(list.files(rdir))==0)) {
      return(experiments)
    }else{
      return(0)
    }

  }else{
    # Avoid downloading the files every time
    message("---> raw files already found: ", id$id)
    return(list.files(rdir, full.names = T))
  }
}

# Download raw data for all datasets
get_raw <- function(ids, dest_dir, ftype="protein",download_date = NULL, rmfile=TRUE, args=NULL){

  # Subset if we have an id  
  if(!is.null(args)){ids <- ids[names(ids)[args]]}
  
  # remove info file if there
  if(file.exists("data/RawDataNotFound.txt") & rmfile){file.remove("data/RawDataNotFound.txt")}
  
  # Loop over ids
  paths <- lapply(ids, function(id) get_db(id = id, dest_dir = dest_dir, ftype = ftype, download_date=download_date))
  
  # Closing all connections in case a file failed to download
  closeAllConnections()
  
  # Report empty folders and correct paths
  paths <- get_test(paths=paths, ids=ids, dest_dir = dest_dir, ftype = ftype, rmfile=rmfile)
  
  return(paths)
}

######### TESTS ###########
# Flag raw directories that are empty
get_test <- function(paths, ids, dest_dir, ftype="protein", rmfile=T){
  
  # Check those folders that are empty
  test <- data.frame(t(sapply(ids, function(id) c(id$id, length(list.files(file.path(dest_dir, id$id, paste("supp", ftype, sep="_"))))))))
  colnames(test) <- c("id", "files")
  test$which <- "all"

  # Finding downloading problems
  fails <- lapply(paths, function(x) check_paths(x, report = T))
  paths <- lapply(paths, function(x) check_paths(x, report = F))
  
  # Write down those that don't pass the test
  fails <- unlist(fails)
  if (length(fails)>0){
    test <- rbind(test, data.frame(id=basename(dirname(dirname(fails))), files=0,which=basename(fails)))
  }

  # Write report
  if (any(as.numeric(test[,2])==0)){
    message("Some of the raw data was not found (and hence the warnings). Find those cases in: data/RawDataNotFound.txt")
    write.table(file = "data/RawDataNotFound.txt", test[as.numeric(test[,2])==0,c("id","which")], row.names = F, col.names = rmfile, append = !rmfile)
  }
  
  return(paths)
}