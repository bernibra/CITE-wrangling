# Download raw files that contain CITE info for one GEO dataset
get_raw <- function(id, target_variable, keyword, georaw, dest_dir, wlink=NULL, ftype="protein"){

  # Define file paths
  basedir <- file.path(dest_dir, id)
  rdir <- file.path(basedir, paste("supp", ftype, sep="_"))
  
  if((!file.exists(rdir))){
    # Create directory if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data")
    
    # Find relevant supplementary files
    experiments <- set_names(list.files(basedir, full.names = T,pattern = "\\.txt.gz$"))%>%
      map(function(x) GEOquery::getGEO(filename = x)) %>%
      map(Biobase::pData)  %>%
      bind_rows() %>%
      mutate(data_processing_lowercase = tolower(!!sym(target_variable))) %>%
      filter(stringr::str_detect(data_processing_lowercase, keyword)) %>%
      pull(!!sym(georaw))
    
    # Download raw data
    experiments %>%
      map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
    
    # Was the data downloaded or is the new directory empty?
    if (length(list.files(rdir))==0){
      # This definition is useful to know what path to return
      experiments <- id
      
      # If still empty, try to use the link directly if available
      if (!is.null(wlink)){

        # Create directory as GEOquery
        dir.create(file.path(rdir, experiments), showWarnings = FALSE)
        
        for(k in 1:length(wlink)){
          # Download links
          download.file(url = wlink[k], destfile = file.path(rdir, experiments, basename(wlink[k])))
        }
        
      }else{
        # if there is no direct link, try getGEOSupp on main id
        experiments %>% map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
      }
      
      # Just ensure that we didn't create an empty directory
      if (length(list.files(file.path(rdir, experiments)))==0){unlink(rdir, recursive = T)}
    }
    
    # Return directories if not empty
    if (!(length(list.files(rdir))==0)) {
      return(paste(rdir, experiments, sep="/"))
    }else{
      return(0)
    }

  }else{
      # Avoid downloading the files every time
      message("---> raw files already found: ", id)
      return(list.files(rdir, full.names = T))
  }
}

# Download raw data for all GEO datasets
get_raw_GEO <- function(ids, dest_dir, ftype="protein",download_date = NULL){
  
  # remove info file if there
  if(file.exists("data/GEORawDataNotFound.txt")){file.remove("data/GEORawDataNotFound.txt")}

  # Loop over ids
  paths <- lapply(ids, function(id) get_raw(id = id$id, target_variable = id$description,
                                   keyword = id$keyword[[ftype]], georaw = id$georaw,
                                   dest_dir = dest_dir, wlink = id$wlink, ftype = ftype)
                  )
  
  # Report empty folders
  get_raw_GEO.test1(ids=ids, dest_dir = dest_dir, ftype = ftype)
  
  return(paths)
}

######### TESTS ###########
# Flag raw directories that are empty
get_raw_GEO.test1 <- function(ids, dest_dir, ftype="protein"){
  
  # Check those folders that are empty
  test <- data.frame(t(sapply(ids, function(id) c(id$id, length(list.files(file.path(dest_dir, id$id, paste("supp", ftype, sep="_"))))))))

  # Closing all connections in case a file failed to download
  closeAllConnections()
  
  # Write report
  if (any(as.numeric(test[,2])==0)){
    message("Some of the GEO raw data was not found (and hence the warnings). Find those cases in: data/GEORawDataNotFound.txt")
    write.table(file = "data/GEORawDataNotFound.txt", test[as.numeric(test[,2])==0,1], row.names = F, col.names = F)
  }

}
  