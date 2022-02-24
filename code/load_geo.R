# Check if one has enough RAM to read the matrix 
should_i_load_this <- function(filename, tolerance=100){
  print(filename)
  return(tolerance > file.size(filename)/as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE)))
}

# Get row and column names for big files
big_row_column <- function(filename){
  # filename <- "~/Downloads/GSE158769_exprs_raw.tsv.gz"
  # a <- readr::read_delim("~/Downloads/GSE158769_exprs_raw.tsv.gz", col_names = TRUE, 
  #                        delim = "\t",
  #                        comment = "#", n_max = 2)

  filename <- "~/Downloads/GSE158769_exprs_raw.tsv"
  dest_dir <- "./"
  
  rcmd <- paste0("cut -f 1 -d'\t' ", filename, " > ", dest_dir, "row-names.csv")
  ccmd <- paste0("head -n 1 ", filename, " > ", dest_dir, "column-names.csv")
  system(rcmd)
  system(ccmd)
  
  rows <- readr::read_delim(paste0(dest_dir, "row-names.csv"), delim = "\t")
  column <- readr::read_delim(paste0(dest_dir, "column-names.csv"), delim = "\t")
}

# Function turning a matrix type object to SingleCellExperiment class
matrix_to_sce <- function(mat, info){
  
  # Transpose the matrix if need be
  if(!(info$transpose)){
    mat <- t(mat)
  }
  
  # Are there any funky columns that need to be added as coldata
  cell_properties <- which(colnames(mat) %in% info$coldata)
  if(length(cell_properties)>0){
    
    # Make data frame with the funky info
    coldata <- mat[,cell_properties, drop=FALSE]
    mat <- mat[,-cell_properties]
    
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)

    }else{
    # Make singleCellObject
    sce <- SingleCellExperiment(assays = list(counts = t(mat)))

  }
}

# Turning a h5 object to SingleCellExperiment class via Seurat
h5_to_sce <- function(filename, info){
  
  # I found this to be the easiest way to get such data into SingleCellExperiment class
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  return(Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5)))

}

# Turning a mtx.gz object into a SingleCellExperiment
mtx_to_sce <- function(filename, info){

  # What are row and what are columns
  features <- gsub(info$replace, info$features, filename)
  cells <- gsub(info$replace, info$cells, filename)

  # Seurat comes in handy for reading interaction-like files into matrix objects
  mtx <- Seurat::ReadMtx(mtx = filename,
                         features = features,
                         cells = cells,
                         feature.column = info$column)

  # Make sure the matrix is in the right order and turn into SingleCellExperiment
  if(info$transpose){
    return(SingleCellExperiment(t(mtx)))
  }else{
    return(SingleCellExperiment(mtx))
  }
}

# Read file type and load data
read_raw <- function(filename, info){
  
  # File formatted as rds
  if (grepl(".rds$|.Rds$", filename)){
    mat <- readRDS(filename)
    return(matrix_to_sce(as.matrix(mat), info$rawformat))
  }
  
  # File formatted as zip rds
  if(grepl(".rds.gz$|.Rds.gz$", filename)){
    mat <- R.utils::gunzip(filename) %>% readRDS()
    return(matrix_to_sce(as.matrix(mat), info$rawformat))
  }
  
  # File formatted csv or tsv
  if (grepl(".csv.gz$|.tsv.gz$", filename)){

    sep <- "," %>% read.delim(file = filename, header = T,
                              nrows = 1, sep=",", comment.char = "#") %>% { ifelse(length(.)>2 ,",", "\t" ) }
    mat <- read.delim(file = filename,
                      header = T,
                      row.names = 1,
                      check.names = FALSE,
                      sep = sep,
                      comment.char = "#")
    
    return(matrix_to_sce(as.matrix(mat), info$rawformat))
  }
  
  # File formatted as h5
  if (grepl(".h5$", filename)){
    return(h5_to_sce(filename, info$rawformat))
  }
  
  # interaction list and complementary files for columns and rows
  if (grepl(".mtx.gz$", filename)){
    return(mtx_to_sce(filename, info$rawformat))
  }
  
  # A directory? jeeeeezzz... 
  if (grepl)
  stop("format not found")
}

# Look for relevant filenames in directory
relevant_files <- function(filenames, keywords=NULL){

  # If there is only one file, then there is no problem
  if (length(filenames)==1){
    return(filenames)
  }

  # Files that have the following extensions are generally the main files 
  if ( any(grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.h5$", filenames)) ){
    filenames <-  filenames[grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.h5$", filenames)]
  }

  # The keywords describe proteins RNA or HTOs generally
  ifelse(!(is.null(keywords)), 
          return(filenames[grepl(keywords, filenames)]), 
          return(filenames))
}

# Load a single geo raw dataset
load_geo_id <- function(paths, info){

  # Go over all supplementary files
  for(path in paths){
    print(path)
    # Find all raw files
    filenames <- list.files(path, full.names = T)

    # Dealing with multiple files if possible
    filenames <- relevant_files(filenames = filenames, keywords = info$rawformat$keyword)
    
    for (idx in 1:length(filenames)){
      
      # Define file name
      rdir <- paste(path, paste0(idx, ".rds"), sep = "_") %>%
        gsub("raw", "processed/protein-data", .) %>%
        gsub("/supp/", "_", .)
      
      # Process raw data and save as SingleCellExperiment class if not done already
      if(!file.exists(rdir)){

        if(should_i_load_this(filenames[idx])){

          # Read raw data and turn into SingleCellExperiment
          # saveRDS(object = read_raw(filename = filenames[idx], info = info), file = rdir)

        }else{

          if (!file.exists("./data/NOTenoughRAM.txt")){

            write("# The following files were not fully processed because you don't have enough RAM in the current machine.",file="./data/NOTenoughRAM.txt",append=TRUE)
            write("# Nevetherless, these are accounted when building the name dictionaries.",file="./data/NOTenoughRAM.txt",append=TRUE)

          }

          # Find row and column names

          # Not enough RAM to read this matrix
          write(filenames[idx],file="./data/NOTenoughRAM.txt",append=TRUE)

        }
        
        return(rdir)
        
      }else{
        message("---> file already processed: ", basename(filenames[idx]))
        return(rdir)
      }
    }
  }
}

# Format all datasets as SingleCellExperiments
load_geo <- function(paths, ids){
  
  # remove info files if there
  if(file.exists("data/NOTenoughRAM.txt")){file.remove("data/NOTenoughRAM.txt")}
  
  # geo dataset names
  datasets <- names(paths)
  
  # load each dataset
  paths_ <- lapply(datasets, function(x) load_geo_id(paths=paths[[x]], info=ids[[x]]))
  
  return(paths_)
}
