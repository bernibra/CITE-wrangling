matrix_to_sce <- function(mat, info){
  if(!(info$transpose)){
    mat <- t(mat)
  }
  cell_properties <- which(colnames(mat) %in% info$coldata)
  if(length(cell_properties)>0){
    coldata <- mat[,cell_properties, drop=FALSE]
    mat <- mat[,-cell_properties]
    sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)
  }else{
    sce <- SingleCellExperiment(assays = list(counts = t(mat)))
  }
}

h5_to_sce <- function(filename, info){
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  return(Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5)))
}

mtx_to_sce <- function(filename, info){
  print(filename)
  features <- gsub(info$replace, info$features, filename)
  cells <- gsub(info$replace, info$cells, filename)
  
  mtx <- Seurat::ReadMtx(mtx = filename, 
                         features = features,
                         cells = cells,
                         feature.column = info$column)
  if(info$transpose){
    return(SingleCellExperiment(t(mtx)))
  }else{
    return(SingleCellExperiment(mtx))
  }
}

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
  if (grepl(".h5$", filename)){
    return(h5_to_sce(filename, info$rawformat))
  }
  if (grepl(".mtx.gz$", filename)){
    return(mtx_to_sce(filename, info$rawformat))
  }
  stop("format not found")
}

# Look for relevant filenames in directory
relevant_files <- function(filenames, keywords=NULL){

  if (length(filenames)==1){
    return(filenames)
  }

  if ( any(grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.h5$", filenames)) ){
    filenames <-  filenames[grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.h5$", filenames)]
  }

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

        print(filenames[idx])
        saveRDS(object = read_raw(filename = filenames[idx], info = info), file = rdir)
        
      }
    }
  }
}

# Format all datasets as SingleCellExperiments
load_geo <- function(paths, ids){
  
  # geo dataset names
  datasets <- names(paths)
  
  # load each dataset
  lapply(datasets, function(x) load_geo_id(paths=paths[[x]], info=ids[[x]]))
  
}