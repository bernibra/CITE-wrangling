###########################################################
# Set of methods to extract rows and columns of big files
###########################################################

# Set method
get_row_column <- function(x) UseMethod("get_row_column")


# if the class if not recognized, simply return NULL values
get_row_column.default <- function(filename){
  return(list(sce=NULL, rownames = NULL, colnames=NULL))
}

# If csv, tsv or txt, run shell commands
get_row_column.csv <- function(filename){
  
  # Create temporal directory
  dest_dir <- file.path(dirname(filename), "tmp")
  dir.create(dest_dir, showWarnings = FALSE)
  
  # Extract rows and columns 
  rcmd <- paste0("cut -f 1 -d'\t' ", filename, " > ", dest_dir, "/row-names.csv")
  ccmd <- paste0("head -n 1 ", filename, " > ", dest_dir, "/column-names.csv")
  system(rcmd)
  system(ccmd)
  
  # Read rows and columns
  rows <- readr::read_delim(paste0(dest_dir, "/row-names.csv"), delim = "\t", comment = "#", show_col_types = F)
  column <- readr::read_delim(paste0(dest_dir, "/column-names.csv"), comment = "#", show_col_types = F)
  
  unlink(dest_dir, recursive = T)
  
  return(list(sce=NULL, rownames = (rows %>% pull(1)), colnames=colnames(column)))
}