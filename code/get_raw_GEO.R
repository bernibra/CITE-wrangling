# Download raw files that contain CITE info for one GEO dataset
get_raw <- function(id, target_variable, keyword, georaw, dest_dir, download_date=NULL){
  basedir <- file.path(dest_dir, id)
  rdir <- file.path(basedir, "supp")
  if(!file.exists(rdir)){
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading raw data on ", download_date)
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

get_raw_GEO <- function(ids, dest_dir, download_date = NULL){
  lapply(ids, function(id) get_raw(id=id$id, target_variable = id$description,
                                   keyword=id$keyword, georaw=id$georaw,
                                   dest_dir = dest_dir))
}