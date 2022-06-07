######################################################
## General-purpose functions for processing raw data
######################################################

# check for empty directories
check_paths <- function(paths, report=F){
  y <- sapply(paths, function(x){length(list.files(x))}, USE.NAMES = T)
  if(report){
    return(names(y)[y==0])
  }else{
    return(names(y)[y!=0])
  }
}

# Unzip if necessary
if_unzip <- function(filename){
  if(grepl(".gz$", filename)){
    R.utils::gunzip(filename)
    filename <- gsub(".gz", "", filename)
  }
  return(filename)
}

decompress_zipfile <- function(file, directory, .file_cache = FALSE) {
  
  if (.file_cache == TRUE) {
    print("decompression skipped")
  } else {
  
  # Set working directory for decompression
  # simplifies unzip directory location behavior
  wd <- getwd()
  setwd(directory)
    
  # Run decompression
  decompression <-
      system2("unzip",
              args = c("-o", # include override flag
                       file),
              stdout = TRUE)
    
  # uncomment to delete archive once decompressed
  file.remove(file) 
  
  # Reset working directory
  setwd(wd)
  rm(wd)
    
  # Test for success criteria
  # change the search depending on 
  # your implementation
  if (grepl("Warning message", tail(decompression, 1))) {
      print(decompression)
    }
  }
  
  # Find and return new file name
  file <- list.files(directory, full.names = T)
  return(file)
}

untar_folder <- function(filenames){
  # Untar
  untar(filenames, exdir = dirname(filenames))

  # Remove compressed folder
  unlink(filenames)
  
  # Find files
  filenames <- list.files(dirname(filenames), full.names = T)
  filenames_y <- list.files(dirname(filenames), recursive = T, full.names = T)
    
  if(!all(filenames==filenames_y)){
    filenames <- paste(dirname(dirname(filenames_y[1])), basename(filenames_y), sep="/")
    # Move files to main directory
    file.rename(from=filenames_y, to=filenames)
    # Remove empty directory
    unlink(dirname(filenames_y[1]), recursive = T)
  }
  return(filenames)
}

# Check if one has enough RAM to read the matrix 
should_i_load_this <- function(filename, tolerance=0.15){
  filename <- if_unzip(filename)
  return(list(
    shouldi=tolerance > file.size(filename)/memuse::swap.unit(memuse::Sys.meminfo()$freeram, "bytes")@size,
    filename=filename)
  )
}

# Use a dictionary to rename features
rename_features <- function(features, dictionary, key, value){
  
  # Load the dictionary
  dict <- readr::read_delim(dictionary, show_col_types = F)[, c(key, value)]
  
  # Basic checks
  dict <- dict[!is.na(dict[,key]),] %>% data.frame
  colnames(dict) <- c("key", "value")
  
  dict %<>% group_by(key) %>% 
    mutate(value = paste0(value, collapse = "|")) %>% distinct(key, .keep_all = T)
  
  # Change the names
  features <- data.frame(key=features)
  
  # Merge both data.frames
  features_ <- merge(x=features, y=dict, by = "key", all.x = TRUE)$value
  
  # Replace names based on dictionary
  features$key[!is.na(features_)] <- features_[!is.na(features_)]
  
  return(features$key)
}

# Get row and column names for big files
split_big_file <- function(filename, chunks=1){
  
  # Create temporal directory
  dest_dir <- file.path(dirname(filename), "splits")
  dir.create(dest_dir, showWarnings = FALSE)
  
  # Extract columns 
  ccmd <- paste0("head -n 1 ", filename, " > ", dest_dir, "/column-names.csv")
  system(ccmd)
  
  # Read columns
  column <- readr::read_delim(paste0(dest_dir, "/column-names.csv"), comment = "#", show_col_types = F)
  
  # Split files
  for (i in 1:(floor(ncol(column)/chunks))){
    rcmd <- paste0("cut -f  ", formatC(1+(chunks*(i-1)), format = "d"), "-", formatC((chunks*i), format = "d"), " -d'\t' ", filename, " > ", dest_dir, "/chunk", i,".csv")
    system(rcmd)
  }
  rcmd <- paste0("cut -f  ", formatC(1+chunks*floor(ncol(column)/chunks), format = "d"), "-", formatC(ncol(column), format = "d"), " -d'\t' ", filename, " > ", dest_dir, "/chunk", i,".csv")
  system(rcmd)
  
  return(0)
}