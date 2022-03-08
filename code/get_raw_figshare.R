get_figshare_id <- function(id, dest_dir, ftype){
  return(0)
}

# Download raw data for all figshare datasets
get_raw_figshare <- function(ids, dest_dir, ftype="protein",download_date = NULL, rmfile=TRUE){
  
  # remove info file if there
  if(file.exists("data/GEORawDataNotFound.txt") & rmfile){file.remove("data/GEORawDataNotFound.txt")}
  
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
    message("Some of the GEO raw data was not found (and hence the warnings). Find those cases in: data/GEORawDataNotFound.txt")
    write.table(file = "data/GEORawDataNotFound.txt", test[as.numeric(test[,2])==0,c("id","which")], row.names = F, col.names = rmfile, append = !rmfile)
  }
  
  return(paths)
}
