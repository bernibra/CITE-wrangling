###################################
## General-purpose functions
###################################

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

# Check if one has enough RAM to read the matrix 
should_i_load_this <- function(filename, tolerance=0.05){
  filename <- if_unzip(filename)
  return(list(
    shouldi=tolerance > file.size(filename)/memuse::swap.unit(memuse::Sys.meminfo()$freeram, "bytes")@size,
    filename=filename)
  )
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