# Download raw files that contain CITE info for one GEO dataset
get_raw <- function(id, target_variable, keyword, georaw, dest_dir){

  # Define file paths
  basedir <- file.path(dest_dir, id)
  rdir <- file.path(basedir, "supp")

  # Check if file is empty
  empty <- length(list.files(rdir))==0

  if((!file.exists(rdir))|(empty)){
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
    
    # Return directories if not empty
    if (!(length(list.files(rdir))==0)) {
      return(paste(rdir, experiments, sep="/"))
    }else{
      return(0)
    }

    }else{

      message("raw files already found")
      return(list.files(rdir, full.names = T))
  }
}

# Download raw data for all GEO datasets
get_raw_GEO <- function(ids, dest_dir, download_date = NULL){
  
  # Loop over ids
  paths <- lapply(ids, function(id) get_raw(id=id$id, target_variable = id$description,
                                   keyword=id$keyword, georaw=id$georaw,
                                   dest_dir = dest_dir)
                  )
  
  # Report empty folders
  get_raw_GEO.test1(ids=ids, dest_dir = dest_dir)
  
  return(paths)
}

######### TESTS ###########
# Flag raw directories that are empty
get_raw_GEO.test1 <- function(ids, dest_dir){
  
  # Check those folders that are empty
  test <- data.frame(t(sapply(ids, function(id) c(id$id, length(list.files(file.path(dest_dir, id$id, "supp")))))))

  # Write report
  if (any(as.numeric(test[,2])==0)){
    warning("Some of the GEO raw data was not found. Find those cases in: data/GEORawDataNotFound.txt")
    write.table(file = "data/GEORawDataNotFound.txt", test[as.numeric(test[,2])==0,1], row.names = F, col.names = F)
  }
  
}
  