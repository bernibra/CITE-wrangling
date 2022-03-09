get_figshare_id <- function(id, dest_dir, ftype){
  
  # Create main directory if not there
  basedir <- file.path(dest_dir, id$id)
  dir.create(basedir, showWarnings = FALSE)
  
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
    if (file.exists(rdir_) & id$wlink[[ftype]]==id$wlink[[possible_types[!(possible_types %in% ftype)]]]){
      R.utils::createLink(link=rdir, target=rdir_)
      message("---> raw files already found: ", id$id)
      return(list.files(rdir, full.names = T))
    }
    
    # Create directory if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data")
    
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
    
  }else{
    # Avoid downloading the files every time
    message("---> raw files already found: ", id$id)
    return(list.files(rdir, full.names = T))
  }
  
}

# Download raw data for all figshare datasets
get_raw_figshare <- function(ids, dest_dir, ftype="protein",download_date = NULL, rmfile=TRUE){
  
  # remove info file if there
  if(file.exists("data/RawDataNotFound.txt") & rmfile){file.remove("data/RawDataNotFound.txt")}
  
  # Loop over ids
  paths <- lapply(ids, function(id) get_figshare_id(id = id, dest_dir = dest_dir, ftype = ftype))
  
  # Closing all connections in case a file failed to download
  closeAllConnections()
  
  # Report empty folders and correct paths
  paths <- get_figshare_test(paths=paths, ids=ids, dest_dir = dest_dir, ftype = ftype, rmfile=rmfile)
  
  return(paths)
}

######### TESTS ###########
# Flag raw directories that are empty
get_figshare_test <- function(paths, ids, dest_dir, ftype="protein", rmfile=T){
  
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
    message("Some of the figshare raw data was not found (and hence the warnings). Find those cases in: data/RawDataNotFound.txt")
    write.table(file = "data/RawDataNotFound.txt", test[as.numeric(test[,2])==0,c("id","which")], row.names = F, col.names = rmfile, append = !rmfile)
  }
  
  return(paths)
}
