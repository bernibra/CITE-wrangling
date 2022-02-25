# Unzip if necessary
if_unzip <- function(filename){
  if(grepl(".gz$", filename)){
    R.utils::gunzip(filename)
    filename <- gsub(".gz", "", filename)
  }
  return(filename)
}

# Check if one has enough RAM to read the matrix 
should_i_load_this <- function(filename, tolerance=0.5){
  filename <- if_unzip(filename)
  return(list(
    shouldi=tolerance > file.size(filename)/memuse::swap.unit(memuse::Sys.meminfo()$freeram, "bytes")@size,
    filename=filename)
    )
}

# Get row and column names for big files
get_row_column <- function(filename, rdir, id){
  
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
  
  # Save row and column names as rds
  saveRDS(object = colnames(column), file = file.path(rdir, paste0("cells_", id)))
  saveRDS(object = rows %>% pull(1), file = file.path(rdir, paste0("features_", id)))
  
  unlink(dest_dir, recursive = T)
  return(0)
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
    mat <- mat[,-cell_properties] %>% as.matrix %>% Matrix::Matrix(., sparse = T)
    
    # Make SingleCellObject
    sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)

    }else{
    # Make singleCellObject
      
    mat  %<>% as.matrix %>% Matrix::Matrix(., sparse = T)
    sce <- SingleCellExperiment(assays = list(counts = t(mat)))

    }
  
  return(sce)
}

# Turning a h5 object to SingleCellExperiment class via Seurat
h5_to_sce <- function(filename, info){
  
  # I found this to be the easiest way to get such data into SingleCellExperiment class
  h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
  return(Seurat::as.SingleCellExperiment(assays = list(counts = Seurat::CreateSeuratObject(h5))))

}

# Turning a mtx.gz object into a SingleCellExperiment
mtx_to_sce <- function(filename, info){

  # What are row and what are columns
  if(!is.null(info$common_features)){
    features <- file.path(dirname(filename), info$common_features)
  }else{
    features <- gsub(info$replace, info$features, filename)
  }
  cells <- gsub(info$replace, info$cells, filename)

  # Seurat comes in handy for reading interaction-like files into matrix objects
  mtx <- Seurat::ReadMtx(mtx = filename,
                         features = features,
                         cells = cells,
                         feature.column = info$column,
                         mtx.transpose = info$transposeMTX
                         )

  # Make sure the matrix is in the right order and turn into SingleCellExperiment
  return(SingleCellExperiment(assays = list(counts = mtx)))
}

# Read file type and load data
read_raw <- function(filename, info){
  
  # File formatted as rds
  if (grepl(".rds$|.Rds$", filename)){
    mat <- readRDS(filename)
    return(matrix_to_sce(as.matrix(mat), info$rawformat))
  }

  
  # File formatted csv or tsv
  if (grepl(".csv$|.tsv$", filename)){
    mat <- readr::read_delim(file = filename, col_names = TRUE,
                           comment = "#", show_col_types = FALSE) %>% tibble::column_to_rownames(colnames(.)[1])
    
    return(matrix_to_sce(mat, info$rawformat))
  }
  
  # File formatted as h5
  if (grepl(".h5$", filename)){
    return(h5_to_sce(filename, info$rawformat))
  }
  
  # interaction list and complementary files for columns and rows
  if (grepl(".mtx$", filename)){
    return(mtx_to_sce(filename, info$rawformat))
  }
  
  stop("format not found")
}

# Look for relevant filenames in directory
relevant_files <- function(filenames, keywords=NULL){

  # A directory? jeeeez...
  if (length(filenames)==1 & all(grepl(".tar.gz$|.tar$", filenames))){
    # Untar
    untar(filenames, exdir = dirname(filenames))
    # Remove compressed folder
    unlink(filenames)
    # Find files
    filenames_ <- list.files(dirname(filenames), recursive = T, full.names = T)
    filenames <- paste(dirname(dirname(filenames_[1])), basename(filenames_), sep="/")
    # Move files to main directory
    file.rename(from=filenames_, to=filenames)
    # Remove empty directory
    unlink(dirname(filenames_[1]), recursive = T)
  }
  
  # If there is only one file, then there is no problem
  if (length(filenames)==1){
    return(filenames)
  }

  # Files that have the following extensions are generally the main files
  filenames_ <- grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.mtx$|.h5.gz$|.h5$", filenames)
  if ( any(filenames_) ){
    filenames <-  filenames[filenames_]
  }

  # The keywords describe proteins RNA or HTOs generally
  ifelse(!(is.null(keywords)), 
          return(filenames[grepl(keywords, filenames)]), 
          return(filenames))
}

# Load a single geo raw dataset
load_geo_id <- function(paths, info, ftype="protein"){

  # Go over all supplementary files
  for(path in paths){
    print(path)
    
    # Find all raw files
    filenames <- list.files(path, full.names = T)

    # Dealing with multiple files if possible
    filenames <- relevant_files(filenames = filenames, keywords = info$rawformat$keyword[[ftype]])
    
    for (idx in 1:length(filenames)){
      
      # Check if we can actually load the document
      shouldi <- should_i_load_this(filenames[idx])
      filenames[idx] <- shouldi$filename
      
      # Define file name
      rdir <- paste(path, paste0(idx, ".rds"), sep = "_") %>%
        gsub("raw", "processed/protein-data", .) %>%
        gsub(paste("/supp", paste0(ftype, "/"), sep="_"), "_", .)
      
      # Process raw data and save as SingleCellExperiment class if not done already
      if(!file.exists(rdir)){

        if(shouldi$shouldi){

          # Read raw data and turn into SingleCellExperiment
          sce <- read_raw(filename = filenames[idx], info = info)
          saveRDS(object = sce, file = rdir)
          
          # Find row and column names
          rdir_ <- file.path("data/processed/names", ftype)
          saveRDS(object = colnames(sce), file = file.path(rdir_, paste0("cells_", basename(rdir))))
          saveRDS(object = rownames(sce), file = file.path(rdir_, paste0("features_", basename(rdir))))

        }else{

          if (!file.exists("./data/NOTenoughRAM.txt")){

            write("# The following files were not fully processed because you don't have enough RAM in the current machine.",file="./data/NOTenoughRAM.txt",append=TRUE)
            write("# Nevetherless, these are accounted when building the name dictionaries.",file="./data/NOTenoughRAM.txt",append=TRUE)

          }

          # Find row and column names
          rdir_ <- file.path("data/processed/names", ftype)
          get_row_column(filenames[idx], rdir = rdir_, id=basename(rdir))
          
          # Not enough RAM to read this matrix
          write(filenames[idx],file="./data/NOTenoughRAM.txt",append=TRUE)

        }
        
      }else{
        message("---> file already processed: ", basename(filenames[idx]))
      }
    }
  }
  return(0)
}

# Format all datasets as SingleCellExperiments
load_geo <- function(paths, ids, ftype="protein"){
  
  # remove info files if there
  if(file.exists("data/NOTenoughRAM.txt")){file.remove("data/NOTenoughRAM.txt")}
  
  # geo dataset names
  datasets <- names(paths)
  
  # load each dataset
  lapply(datasets, function(x) load_geo_id(paths=paths[[x]], info=ids[[x]], ftype=ftype))
  
  return(list.files("data/processed/protein-data/"))
}
