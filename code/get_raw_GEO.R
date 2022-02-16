# Download raw files that contain CITE info for one GEO dataset
get_raw <- function(id, target_variable, keyword, georaw, dest_dir, download_date=NULL){

  # Define file paths
  basedir <- file.path(dest_dir, id)
  rdir <- file.path(basedir, "supp")

  # Check if file is empty
  empty <- length(list.files(rdir))==0

  if((!file.exists(rdir))|(empty)){
    # Create directory if not there
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data on ", download_date)
    
    # Download raw data
    experiments <- set_names(list.files(basedir, full.names = T,pattern = "\\.txt.gz$"))%>%
      map(function(x) GEOquery::getGEO(filename = x)) %>%
      map(Biobase::pData)  %>%
      bind_rows() %>%
      mutate(data_processing_lowercase = tolower(!!sym(target_variable))) %>%
      filter(stringr::str_detect(data_processing_lowercase, keyword)) %>%
      pull(!!sym(georaw)) %>%
      map(GEOquery::getGEOSuppFiles, baseDir = rdir)

    }else{

      message("raw files already found")
      return(0)
  }
}

# Download raw data for all GEO datasets
get_raw_GEO <- function(ids, dest_dir, download_date = NULL){
  
  # Loop over ids
  lapply(ids, function(id) get_raw(id=id$id, target_variable = id$description,
                                   keyword=id$keyword, georaw=id$georaw,
                                   dest_dir = dest_dir))
  
  # Report empty folders
  get_raw_GEO.test1(ids=ids, dest_dir = dest_dir)
}

######### TESTS ###########
# Flag raw directories that are empty
get_raw_GEO.test1 <- function(ids, dest_dir){
  
  # Check those folders that are empty
  test <- data.frame(t(sapply(ids, function(id) c(id$id, length(list.files(file.path(dest_dir, id$id, "supp")))))))
  
  # Write report
  write.table(file = "data/GEORawDataNotFound.txt", test[as.numeric(test[,2])==0,1], row.names = F, col.names = F)

}
  