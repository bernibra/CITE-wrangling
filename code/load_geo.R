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

        # Read raw data and turn into SingleCellExperiment
        saveRDS(object = read_raw(filename = filenames[idx], info = info), file = rdir)
        return(rdir)
        
      }
    }
  }
}

# Format all datasets as SingleCellExperiments
load_geo <- function(paths, ids){
  
  # geo dataset names
  datasets <- names(paths)
  
  # load each dataset
  paths_ <- lapply(datasets, function(x) load_geo_id(paths=paths[[x]], info=ids[[x]]))
  
  return(paths_)
}