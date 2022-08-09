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
  if (grepl(".csv$|.tsv$|.txt$|.csv.gz$|.tsv.gz$|.txt.gz$", filename)){
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
  
  if (class(mat)[1]!="dgCMatrix"){
    # Check if it contains coldata within the matrix
    mat <- extract_coldata(mat, info)
    coldata <- mat$coldata
    
    # Turn into sparse matrix
    mat <- as.matrix(mat$mat)
    mat <- Matrix::Matrix(mat, sparse = T)
  }else{
    coldata <- NULL
  }

  return(matrix_to_sce(mat, info, coldata, filename))
  
}

# Function turning a matrix type object to SingleCellExperiment class
read_raw.csv <- function(filename, info, ...){
  
  # Load file as matrix using readr and tibble
  mat <- readr::read_delim(file = filename, col_names = TRUE,
                           comment = "#", show_col_types = FALSE)
  mat[[1]] <- mat %>% pull(colnames(.)[1]) %>% make.names(unique = T)
  mat %<>% tibble::column_to_rownames(colnames(.)[1])

  # Check if it contains coldata within the matrix
  mat <- extract_coldata(mat, info)
  coldata <- mat$coldata
  
  # Turn into sparse matrix
  mat <- as.matrix(mat$mat)
  mat <- Matrix::Matrix(mat, sparse = T)
  
  return(matrix_to_sce(mat, info, coldata, filename)) 
}

# Function turning a matrix type object to SingleCellExperiment class
read_raw.fastcsv <- function(filename, info, ...){
  # Load file as matrix using readr and tibble
  mat <- data.table::fread(filename)
  
  # Define colnames and rownames
  colnames_ <- colnames(mat)
  rownames_ <- mat[[1]]
  rownames_ <- make.names(rownames_, unique = T)
  
  # removing the first column
  cols <- colnames_[1]
  mat <- select(mat, -one_of(cols))
  
  # Turn into sparse matrix
  mat <- as.matrix(mat)
  mat <- Matrix::Matrix(mat, sparse=T)
  
  # Assigning rownames
  rownames(mat) <- rownames_

  return(matrix_to_sce(mat, info, coldata=NULL, filename))
}

# Turning a h5 object to SingleCellExperiment class via Seurat
read_raw.h5 <- function(filename, info, ...){
  
  # I found this to be the easiest way to get such data into SingleCellExperiment class
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  if(!is.null(info$h5key)){
    h5 <- h5[[info$h5key]]
  }
  sce <- Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5))
  
  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Turning a h5seurat object to SingleCellExperiment class via Seurat
read_raw.h5seurat <- function(filename, info, ...){
  
  # Load the assay
  key <- info$h5key
  sce <- Seurat::as.SingleCellExperiment(SeuratDisk::LoadH5Seurat(file=as.character(filename), assays = c(key)))
  
  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
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

  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
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

  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
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

  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Customizable access function for weird rds files
read_raw.h5ad <- function(filename, info, ...){
  
  # Open file in memory
  sce <- zellkonverter::readH5AD(as.character(filename))
  
  # Check name for assay
  if(length(names(assays(sce)))==1){
    if(names(assays(sce))!="counts"){
      names(assays(sce)) <- "counts"
    }
  }

  # Move to colData if necessary
  sce <- sce_move_to_coldata(sce, info$coldata)
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

extract_coldata <- function(mat, info){
  # Do we need to transpose?
  tp <- info$transpose
  
  # Transpose the matrix if need be
  if(is.null(tp)){
    tp <- ncol(mat)<nrow(mat)
  }
  
  coldata=NULL
  
  if(tp){
    # Are there any funky columns that need to be added as coldata
    cell_properties <- which(colnames(mat) %in% info$coldata)
    
    if(length(cell_properties)>0){
      
      # Make data frame with the funky info
      coldata <- mat[,cell_properties, drop=FALSE]

      # Remove weird info
      mat <- select(mat, -cell_properties)
    }
    
  }else{
    # Are there any funky columns that need to be added as coldata
    cell_properties <- which(rownames(mat) %in% info$coldata)
    
    if(length(cell_properties)>0){
      
      # Make data frame with the funky info
      coldata <- mat[cell_properties,, drop=FALSE]
      coldata <- t(coldata)
      
      # Remove weird info
      mat <- mat[-cell_properties,]
    }
  }
  
  return(list(mat=mat, coldata=coldata))
}

# Utility function useful for the read_raw method
matrix_to_sce <- function(mat, info, coldata, filename, ...){
  
  # Do we need to transpose?
  tp <- info$transpose
  
  # Transpose the matrix if need be
  if(is.null(tp)){
    tp <- ncol(mat)<nrow(mat)
  }
  
  # Transpose if necessary
  if(tp){
    mat <- Matrix::t(mat)
  }

  mat <- DelayedArray::DelayedArray(seed = mat)
  
  if(!is.null(info$drop)){
    drop <- grepl(info$drop, rownames(mat))
    mat <- mat[!drop, ]
  }
  if(!is.null(info$keep)){
    keep <- grepl(info$keep, rownames(mat))
    mat <- mat[keep, ]
  }
  
  if(is.null(coldata)){
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = mat))
    
  }else{
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = mat), colData=coldata)
  }
  
  # Add sample information if necessary
  sce <- read_metadata(sce = sce, info = info, path = dirname(filename))
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

# Default read metadata, guessing file type and loading data
read_metadata <- function(sce, info, path){
  
  # Root path
  rdir <- file.path(dirname(dirname(path)), "metadata")
  rdir_ <- dirname(path)
  
  # Skip if we are missing information
  if(is.null(info$samples)){
    return(sce)
  }else{
    # If the metadata is already there, simply change the name
    if(typeof(info$samples)=="character"){
      if(all(info$samples %in% colnames(colData(sce)))){
        
        if(length(info$samples)==1){
          colData(sce)["SAMPLE_ID"] <- colData(sce)[info$samples]
        }else{
          sampleid <- colData(sce) %>%
            data.frame() %>%
            mutate(SAMPLE_ID = paste(!!!syms(info$samples), sep="_")) %>%
            select(SAMPLE_ID)
          colData(sce) <- cbind(colData(sce), sampleid)
        }
      }
      
    }else if(typeof(info$samples)=="list"){
      
      if(!is.null(info$samples$file)){
        filename <- list.files(rdir, full.names = T)
        filename <- filename[grepl(info$samples$file, basename(filename))]
        
        if(length(filename)==0){
          filename <- list.files(rdir_, full.names = T)
          filename <- filename[grepl(info$samples$file, basename(filename))]
        }
        
        filename <- if_unzip(filename)
        
        # File formatted as rds
        if (grepl(".rds$", tolower(filename))){
          meta <- readRDS(filename)
        }
        # File formatted csv, tsv or txt
        if (grepl(".csv$|.tsv$|.txt$|.csv.gz$|.tsv.gz$|.txt.gz$", tolower(filename))){
          meta <- readr::read_delim(filename, comment = "#", show_col_types = FALSE, col_names = TRUE)
        }
        
        if(!is.null(info$samples$key)){
          # Reformat metadata and extract relevant info
          meta %<>% tibble::rownames_to_column("RowNames") %>%
            dplyr::rename(CELL_ID = sym(c(info$samples$key))) %>%
            mutate(SAMPLE_ID = paste(!!!syms(info$samples$value), sep="_"))
          
          meta <- meta[match(rownames(colData(sce)),meta$CELL_ID),] %>%
            tibble::column_to_rownames(var="CELL_ID")
          
          if(identical(rownames(meta), colnames(sce))){
            colData(sce) <- cbind(colData(sce), meta)
          }else{
            warning(paste0("Problem adding metadata to ", basename(path)))
          }
        }
      }
    }
  }
  return(sce)  
}

