################################################
# Set of methods to read different file types
################################################

# Set method
read_raw <- function(x) UseMethod("read_raw")

# Default read raw, guessing file type and loading data
read_raw.default <- function(filename, ...){
  
  # interaction list and complementary files for columns and rows
  if (grepl(".mtx$", filename)){
    return(read_raw.mtx(filename))
  }

  # File formatted as rds
  if (grepl(".rds$|.Rds$", filename)){
    return(read_raw.rds(filename))
  }
  
  # File formatted csv, tsv or txt
  if (grepl(".csv$|.tsv$|.txt$", filename)){
    return(read_raw.csv(filename))
  }
  
  # File formatted as h5
  if (grepl(".h5$", filename)){
    return(read_raw.h5(filename))
  }
  
  stop("format not found")
}

# Read rds and consider it a csv
read_raw.rds <- function(filename, ...){
  
  mat <- readRDS(filename)
  return(matrix_to_sce(mat))
  
}

# Function turning a matrix type object to SingleCellExperiment class
read_raw.csv <- function(filename, ...){
  # Load file as matrix using readr and tibble
  mat <- readr::read_delim(file = filename, col_names = TRUE,
                           comment = "#", show_col_types = FALSE)
  mat[[1]] <- mat %>% pull(colnames(.)[1]) %>% make.names(unique = T)
  mat %<>% tibble::column_to_rownames(colnames(.)[1])
 
  return(matrix_to_sce(mat)) 
}

# Turning a h5 object to SingleCellExperiment class via Seurat
read_raw.h5 <- function(filename, ...){
  
  # I found this to be the easiest way to get such data into SingleCellExperiment class
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  if(!is.null(info$h5key)){
    h5 <- h5[[info$h5key]]
  }
  sce <- Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5))
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Turning a mtx.gz object into a SingleCellExperiment
read_raw.mtx <- function(filename, ...){
  
  # Find other relevant files
  othernames <- list.files(path = dirname(filename), pattern=gsub(info$replace, "*", basename(filename)), full.names = T)
  othernames <- othernames[!(othernames %in% filename)]
  
  # What are row and what are columns
  if(!is.null(info$common_features)){
    features <- file.path(dirname(filename), info$common_features)
  }else{
    features <- othernames[grepl(info$features, othernames)][1]
  }
  
  if(!is.null(info$common_cells)){
    cells <- file.path(dirname(filename), info$common_cells)
  }else{
    cells <- othernames[grepl(info$cells, othernames)][1]
  }
  
  # Should I transpose the matrix?
  mtx.transpose <- info$transpose
  
  # What column should I pick
  feature.column <- ifelse(is.null(info$column), info$column, info$column)
  
  # Seurat comes in handy for reading interaction-like files into matrix objects
  mtx <- Seurat::ReadMtx(mtx = filename,
                         features = features,
                         cells = cells,
                         feature.column = feature.column,
                         mtx.transpose = mtx.transpose
  )
  
  # Make sure the matrix is in the right order and turn into SingleCellExperiment
  sce <- SingleCellExperiment(assays = list(counts = mtx))
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

read_raw.Seurat <- function(filename, ...){
  rds <- readRDS(filename)
  sce <- Seurat::as.SingleCellExperiment(rds)
  if(!is.null(info$altexp)){
    sce <- altExp(sce, info$altexp)
  }
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Customizable access function for weird rds files
read_raw.access <- function(filename, ...){
    eval(parse(text = paste0("f <- function(x){return(", info$access, ")}")))
    sce <- SingleCellExperiment(assays = list(counts = f(rds)))
    return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Utility function useful for the read_raw method
matrix_to_sce <- function(mat, ...){
  
  # Do we need to transpose?
  tp <- info$transpose
  
  # Transpose the matrix if need be
  if(is.null(tp)){
    tp <- ncol(mat)<nrow(mat)
  }
  if(!(tp)){
    mat <- t(mat)
  }
  
  # Are there any funky columns that need to be added as coldata
  cell_properties <- which(colnames(mat) %in% info$coldata)
  
  if(length(cell_properties)>0){
    
    # Make data frame with the funky info
    coldata <- mat[,cell_properties, drop=FALSE]
    mat <- mat[,-cell_properties] %>% as.matrix %>% Matrix::Matrix(., sparse = T)
    
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)
    
  }else{
    # Make singleCellObject
    
    mat  %<>% as.matrix %>% Matrix::Matrix(., sparse = T)
    sce <- SingleCellExperiment(assays = list(counts = t(mat)))
    
  }
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}
