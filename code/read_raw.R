################################################
# Set of methods to read different file types
################################################

# Set method
read_raw <- function(filename, info) UseMethod("read_raw", filename)

# Default read raw, guessing file type and loading data
read_raw.default <- function(filename, info, ...){
  
  # interaction list and complementary files for columns and rows
  if (grepl(".mtx$", filename)){
    return(read_raw.mtx(filename, info))
  }

  # File formatted as rds
  if (grepl(".rds$|.Rds$", filename)){
    return(read_raw.rds(filename, info))
  }
  
  # File formatted csv, tsv or txt
  if (grepl(".csv$|.tsv$|.txt$", filename)){
    return(read_raw.csv(filename, info))
  }
  
  # File formatted as h5
  if (grepl(".h5$", filename)){
    return(read_raw.h5(filename, info))
  }
  
  stop("format not found")
}

# Read rds and consider it a csv
read_raw.rds <- function(filename, info, ...){
  
  mat <- readRDS(filename)
  return(matrix_to_sce(mat, info, filename))
  
}

# Function turning a matrix type object to SingleCellExperiment class
read_raw.csv <- function(filename, info, ...){
  # Load file as matrix using readr and tibble
  mat <- readr::read_delim(file = filename, col_names = TRUE,
                           comment = "#", show_col_types = FALSE)
  mat[[1]] <- mat %>% pull(colnames(.)[1]) %>% make.names(unique = T)
  mat %<>% tibble::column_to_rownames(colnames(.)[1])
 
  return(matrix_to_sce(mat, info, filename)) 
}

# Turning a h5 object to SingleCellExperiment class via Seurat
read_raw.h5 <- function(filename, info, ...){
  
  # I found this to be the easiest way to get such data into SingleCellExperiment class
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  if(!is.null(info$h5key)){
    h5 <- h5[[info$h5key]]
  }
  sce <- Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5))
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Turning a h5seurat object to SingleCellExperiment class via Seurat
read_raw.h5seurat <- function(filename, info, ...){
  
  sce <- Seurat::as.SingleCellExperiment(SeuratDisk::LoadH5Seurat(filename, assays = list(info$h5key = c("counts"))))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Turning a mtx.gz object into a SingleCellExperiment
read_raw.mtx <- function(filename, info, ...){
  
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
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

read_raw.Seurat <- function(filename, info, ...){
  # Open rds and easy sce conversion
  rds <- readRDS(filename)
  sce <- Seurat::as.SingleCellExperiment(rds)
  
  # Make sure we are using the right data
  if(!is.null(info$altexp)){
    cdata <- colData(sce)
    sce <- altExp(sce, info$altexp)
    
    # Make sure that the coldata was passed to the altExp
    if(length(colData(sce))==0){
      colData(sce) <- cdata
    }
  }
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Customizable access function for weird rds files
read_raw.access <- function(filename, info, ...){
  
  # This could be any weird format that comes as an rds file. info$access can be any access function
  rds <- readRDS(filename)
  object <- eval(parse(text = paste0("(function(x){return(", info$access, ")})")))(rds)
  
  # Make sure that the coldata was accessed as well
  if(!is.null(info$coldata)){
    coldata <- eval(parse(text = paste0("(function(x){return(", info$coldata, ")})")))(rds)
    sce <- SingleCellExperiment(assays = list(counts = object), colData = as.data.frame(coldata)) 
  }else{
    sce <- SingleCellExperiment(assays = list(counts = object))
  }
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Customizable access function for weird rds files
read_raw.h5ad <- function(filename, info, ...){
  
  sce <- zellkonverter::readH5AD(raw_dat)

  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Utility function useful for the read_raw method
matrix_to_sce <- function(mat, info, filename, ...){
  
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
    mat <- mat[,-cell_properties] %>% DelayedArray::DelayedArray(seed = .)
    
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)
    
  }else{
    # Make singleCellObject
    
    mat  %<>%  DelayedArray::DelayedArray(seed = .)
    sce <- SingleCellExperiment(assays = list(counts = t(mat)))
    
  }
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Default read metadata, guessing file type and loading data
read_metadata <- function(sce, info, path){
  
  # Root path
  rdir <- file.path(dirname(dirname(path)), "metadata")
  
  # Check if there is external metadata for this database
  if(!file.exists(rdir)){
    if(!is.null(info$samples)){
      colData(sce)["SAMPLE_ID"] <- colData(sce)[info$samples]
    }
    return(sce)
  }
  
  # Skip if we are missing information
  if(file.exists(rdir)  & is.null(info$samples)){
    return(sce)
  }
  
  # Find filename for metadata
  filename <- list.files(rdir, full.names = T)
  filename <- if_unzip(filename[grepl(info$samples$file, filename)])
  
  # File formatted as rds
  if (grepl(".rds$", tolower(filename))){
    meta <- readRDS(filename)
  }
  
  # File formatted csv, tsv or txt
  if (grepl(".csv$|.tsv$|.txt$", tolower(filename))){
    meta <- readr::read_delim(filename, comment = "#", show_col_types = FALSE, col_names = TRUE)
  }
  
  # Reformat metadata and extract relevant info
  meta %<>% tibble::rownames_to_column("RowNames") %>%
    dplyr::rename(CELL_ID = sym(c(info$samples$key))) %>%
    mutate(SAMPLE_ID = paste(!!!syms(info$samples$value)), sep="_") %>%
    select(CELL_ID, SAMPLE_ID)
  
  colData(sce)["SAMPLE_ID"] = meta$SAMPLE_ID[match(rownames(colData(sce)),meta$CELL_ID)]

  return(sce)  
}
