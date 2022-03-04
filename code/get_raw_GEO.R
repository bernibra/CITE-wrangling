# Download raw files that contain CITE info for one GEO dataset
get_raw <- function(id, dest_dir, ftype="protein"){

  # Quick check
  possible_types <- c("rna", "protein")
  if(!(ftype %in% possible_types)){
    stop("Wha'choo talkin' 'bout, Willis?")
  }
  
  # Define file paths
  basedir <- file.path(dest_dir, id$id)
  rdir <- file.path(basedir, paste("supp", ftype, sep="_"))
  rdir_ <- file.path(basedir, paste("supp", possible_types[!(possible_types %in% ftype)], sep="_"))
  
  if((!file.exists(rdir))){
    # Avoid downloading the same data twice
    if (file.exists(rdir_) & id$keyword[[ftype]]==id$keyword[[possible_types[!(possible_types %in% ftype)]]]){
      R.utils::createLink(link=rdir, target=rdir_)
      message("---> raw files already found: ", id$id)
      return(list.files(rdir, full.names = T))
    }
    
    # Create directory if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data")
    
    if(!(is.null(id$description))){
      # Find relevant supplementary files
      experiments <- set_names(list.files(basedir, full.names = T,pattern = "\\.txt.gz$"))%>%
        map(function(x) GEOquery::getGEO(filename = x)) %>%
        map(Biobase::pData)  %>%
        bind_rows() %>%
        mutate(data_processing_lowercase = tolower(!!sym(id$description))) %>%
        filter(stringr::str_detect(data_processing_lowercase, id$keyword[[ftype]])) %>%
        pull(!!sym(id$georaw))
      
      # Download raw data
      experiments %>%
        map(quietly(GEOquery::getGEOSuppFiles), baseDir = rdir)
    }
    
    # Was the data downloaded or is the new directory empty?
    if (length(list.files(rdir))==0){
      # This definition is useful to know what path to return
      experiments <- id$id
      
      # If still empty, try to use the link directly if available
      if (!is.null(id$wlink)){

        # Create directory as GEOquery
        dir.create(file.path(rdir, experiments), showWarnings = FALSE)
        
        for(k in 1:length(id$wlink[[ftype]])){
          # Download links
          download.file(url = id$wlink[[ftype]][k], destfile = file.path(rdir, experiments, basename(id$wlink[[ftype]][k])))
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
      message("---> raw files already found: ", id$id)
      return(list.files(rdir, full.names = T))
  }
}


Tmp_get_raw_GEO <- function(){
  ids=readd(geo_meta)
  dest_dir = "data/raw"
  ftype="rna"
  download_date = NULL
  
  # 4 was the number
  x=ids[[12]]
  id = x
  print(id$id)
  
  
}

# Download raw data for all GEO datasets
get_raw_GEO <- function(ids, dest_dir, ftype="protein",download_date = NULL, rmfile=TRUE){
    
  # remove info file if there
  if(file.exists("data/GEORawDataNotFound.txt") & rmfile){file.remove("data/GEORawDataNotFound.txt")}

  # Loop over ids
  paths <- lapply(ids, function(id) get_raw(id = id, dest_dir = dest_dir, ftype = ftype))
  
  # Closing all connections in case a file failed to download
  closeAllConnections()
  
  # Report empty folders and correct paths
  paths <- get_raw_GEO.test1(paths=paths, ids=ids, dest_dir = dest_dir, ftype = ftype, rmfile=rmfile)
  
  return(paths)
}

######### TESTS ###########
# empty directories
check_paths <- function(paths, report=F){
  y <- sapply(paths, function(x){length(list.files(x))}, USE.NAMES = T)
  if(report){
    return(names(y)[y==0])
  }else{
    return(names(y)[y!=0])
  }
}

# Flag raw directories that are empty
get_raw_GEO.test1 <- function(paths, ids, dest_dir, ftype="protein", rmfile=T){
  
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
    message("Some of the GEO raw data was not found (and hence the warnings). Find those cases in: data/GEORawDataNotFound.txt")
    write.table(file = "data/GEORawDataNotFound.txt", test[as.numeric(test[,2])==0,c("id","which")], row.names = F, col.names = rmfile, append = !rmfile)
  }

  return(paths)
}
  