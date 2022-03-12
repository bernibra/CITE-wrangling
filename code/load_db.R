# Write file with warnings for low RAM
write_warning_file <- function(scelist, filename){
  if (!file.exists("./data/NOTenoughRAM.txt")){
    
    write("# The following files were not fully processed because you don't have enough RAM in the current machine.",file="./data/NOTenoughRAM.txt",append=TRUE)
    write("# Nevetherless, some could be accounted for when building the name dictionaries.",file="./data/NOTenoughRAM.txt",append=TRUE)
    write("file,accounted",file="./data/NOTenoughRAM.txt",append=TRUE)
  }
  
  # Save the reformatted data as an rds file
  if(is.null(scelist$sce)){
    accounted <- ifelse(!is.null(scelist$colnames), "T", "F")
    # Not enough RAM to read this matrix
    write(paste(c(filename, accounted), collapse = ","),file="./data/NOTenoughRAM.txt",append=TRUE)
  }
  
  return(0)  
}

# # Function turning a matrix type object to SingleCellExperiment class
# matrix_to_sce <- function(mat, info){
#   
#   tp <- info$transpose
#   
#   # Transpose the matrix if need be
#   if(is.null(tp)){
#     tp <- ncol(mat)<nrow(mat)
#   }
#   if(!(tp)){
#       mat <- t(mat)
#   }
#   
#   # Are there any funky columns that need to be added as coldata
#   cell_properties <- which(colnames(mat) %in% info$coldata)
#   
#   if(length(cell_properties)>0){
#     
#     # Make data frame with the funky info
#     coldata <- mat[,cell_properties, drop=FALSE]
#     mat <- mat[,-cell_properties] %>% as.matrix %>% Matrix::Matrix(., sparse = T)
#     
#     # Make SingleCellObject
#     sce <- SingleCellExperiment(assays = list(counts = t(mat)), colData=coldata)
# 
#     }else{
#     # Make singleCellObject
#       
#     mat  %<>% as.matrix %>% Matrix::Matrix(., sparse = T)
#     sce <- SingleCellExperiment(assays = list(counts = t(mat)))
# 
#     }
#   
#   return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
# }
# 
# # Turning a h5 object to SingleCellExperiment class via Seurat
# h5_to_sce <- function(filename, info, ftype){
#   
#   # I found this to be the easiest way to get such data into SingleCellExperiment class
#   h5 <- Seurat::Read10X_h5(filename, use.names = TRUE, unique.features = TRUE)
#   if(!is.null(info$h5key)){
#     h5 <- h5[[info$h5key[[ftype]]]]
#   }
#   sce <- Seurat::as.SingleCellExperiment(Seurat::CreateSeuratObject(h5))
#   return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
# }
# 
# # Turning a mtx.gz object into a SingleCellExperiment
# mtx_to_sce <- function(filename, info, ftype){
# 
#   # Find other relevant files
#   othernames <- list.files(path = dirname(filename), pattern=gsub(info$replace, "*", basename(filename)), full.names = T)
#   othernames <- othernames[!(othernames %in% filename)]
#   
#   # What are row and what are columns
#   if(!is.null(info$common_features)){
#     features <- file.path(dirname(filename), info$common_features)
#   }else{
#     features <- othernames[grepl(info$features, othernames)][1]
#   }
# 
#   if(!is.null(info$common_cells)){
#     cells <- file.path(dirname(filename), info$common_cells)
#   }else{
#     cells <- othernames[grepl(info$cells, othernames)][1]
#   }
#   
#   # Should I transpose the matrix?
#   mtx.transpose <- ifelse(is.null(info$transposeMTX[[ftype]]), info$transposeMTX, info$transposeMTX[[ftype]])
# 
#   # What column should I pick
#   feature.column <- ifelse(is.null(info$column[[ftype]]), info$column, info$column[[ftype]])
#   
#   # Seurat comes in handy for reading interaction-like files into matrix objects
#   mtx <- Seurat::ReadMtx(mtx = filename,
#                          features = features,
#                          cells = cells,
#                          feature.column = feature.column,
#                          mtx.transpose = mtx.transpose
#                          )
# 
#   # Make sure the matrix is in the right order and turn into SingleCellExperiment
#   sce <- SingleCellExperiment(assays = list(counts = mtx))
#   return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
# }
# 
# rds_to_sce <- function(rds, info, ftype){
#   if("Seurat" %in% class(rds)){
#     sce <- Seurat::as.SingleCellExperiment(rds)
#     if(!is.null(info$altexp[[ftype]])){
#       sce <- altExp(sce, info$altexp[[ftype]])
#     }
#     return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
#     
#   }else if("matrix" %in% class(rds)){
#     return(matrix_to_sce(as.matrix(rds), info))
#     
#   }else{
#     eval(parse(text = paste0("f <- function(x){return(", info$access[[ftype]], ")}")))
#     sce <- SingleCellExperiment(assays = list(counts = f(rds)))
#     return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
#     
#   }
# }
# 
# # Read file type and load data
# read_raw <- function(filename, info, ftype, shouldi){
#   print(filename)
#   forceANY <- "None"
#   # TODO: Make this more generalizable...
#   if(!is.null(info$force[[ftype]])){
#     if(info$force[[ftype]]=="mtx"){
#       forceANY <- "mtx"
#     }
#   }
#   
#   # interaction list and complementary files for columns and rows
#   if (grepl(".mtx$", filename) | forceANY=="mtx"){
#     ifelse(shouldi, return(mtx_to_sce(filename, info, ftype)), return(NULL))
#   }
#   
#   # File formatted as rds
#   if (grepl(".rds$|.Rds$", filename)){
#     ifelse(shouldi, return(rds_to_sce(readRDS(filename), info, ftype)), return(NULL))
#   }
#   
#   # File formatted csv or tsv
#   if (grepl(".csv$|.tsv$|.txt$", filename)){
#     if(shouldi){
#       mat <- readr::read_delim(file = filename, col_names = TRUE,
#                                comment = "#", show_col_types = FALSE)
#       mat[[1]] <- mat %>% pull(colnames(.)[1]) %>% make.names(unique = T)
#       mat %<>% tibble::column_to_rownames(colnames(.)[1])
#       
#       return(matrix_to_sce(mat, info))
#     }else{
#       return(get_row_column(filename))
#     }
#   }
#   
#   # File formatted as h5
#   if (grepl(".h5$", filename)){
#     ifelse(shouldi, return(h5_to_sce(filename, info, ftype)), return(NULL))
#   }
#   
#   stop("format not found")
# }

# Look for relevant filenames in directory
select_relevant_files <- function(filenames, info){

  # A directory? jeeeez...
  if (length(filenames)==1 & all(grepl(".tar.gz$|.tar$", filenames))){
    # Untar
    untar(filenames, exdir = dirname(filenames))
    # Remove compressed folder
    unlink(filenames)
    # Find files
    filenames_x <- list.files(dirname(filenames), full.names = T)
    filenames_y <- list.files(dirname(filenames), recursive = T, full.names = T)
    
    if(!all(filenames_x==filenames_y)){
      filenames <- paste(dirname(dirname(filenames_y[1])), basename(filenames_y), sep="/")
      # Move files to main directory
      file.rename(from=filenames_y, to=filenames)
      # Remove empty directory
      unlink(dirname(filenames_y[1]), recursive = T)
    }
  }
  
  # If there is only one file, then there is no problem
  if (length(filenames)==1){
    return(filenames)
  }
  
  # TODO: Make this more generalizable...
  if(!is.null(info$force)){
    if(info$force=="mtx"){
      return(filenames[grepl(info$replace, filenames)])
    }
  }

  # Files that have the following extensions are generally the main files
  filenames_ <- grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.mtx$|.h5.gz$|.h5$", filenames)
  if ( any(filenames_) ){
    filenames <-  filenames[filenames_]
  }

  # The keywords describe proteins RNA or HTOs generally
  ifelse(!(is.null(info$keyword)), 
          return(filenames[grepl(info$keyword, filenames)]), 
          return(filenames))
}

# Load a single geo raw dataset
load_path <- function(path, info, ftype="protein"){

  # Find all raw files
  filenames <- list.files(path, full.names = T)

  # Dealing with multiple files if possible
  filenames <- select_relevant_files(filenames = filenames, info = info)

  for (idx in 1:length(filenames)){

    # Define file name
    rdir <- paste(path, paste0(idx, ".rds"), sep = "_") %>%
      gsub("raw", paste0("processed/",ftype,"-data"), .) %>%
      gsub(paste("/supp", paste0(ftype, "/"), sep="_"), "_", .)
    rdir_ <- file.path("data/processed/names", ftype)

    # Process raw data and save as SingleCellExperiment class if not done already
    if(!file.exists(rdir)){
      # Check if we can actually load the document
      shouldi <- should_i_load_this(filenames[idx])
        
      # Define class
      filename <- structure(shouldi$filename, class=info$class)

      # Read raw data and turn into SingleCellExperiment
      if(shouldi$shouldi){
        sce <- read_raw(filename)
      }else{
        sce <- get_row_column(filename)
      }

      # If the dataset has a dictionary, use to rename the features
      if(!is.null(info$dictionary) & !is.null(sce$rownames)){
        sce$rownames <- rename_features(features=sce$rownames, dictionary=file.path(path, info$dictionary$file),
                                 key=info$dictionary$key,
                                 value=info$dictionary$value)
      }

      # Save the reformatted data as an rds file
      if(!is.null(sce$sce)){saveRDS(object = sce$sce, file = rdir)}

      # Find row and column names
      if(!is.null(sce$colnames)){saveRDS(object = sce$colnames, file = file.path(rdir_, paste0("cells_", basename(rdir))))}
      if(!is.null(sce$rownames)){saveRDS(object = sce$rownames, file = file.path(rdir_, paste0("features_", basename(rdir))))}

      # Write Warning file if necessary
      write_warning_file(sce, filenames[idx])

      # Compress files again to avoid using too much disc
      # if(!(grepl(".gz$", filenames[idx]))){zip(zipfile = paste0(filenames[idx], ".gz"), files = filenames[idx])}

    }else{
      message("---> file already processed: ", basename(filenames[idx]))
    }
  }

  return(0)
}

# Format all datasets as SingleCellExperiments
load_db <- function(paths, ids, database, ftype="protein", rmfile=TRUE){
  
  # remove info files if there
  if(file.exists("data/NOTenoughRAM.txt") & rmfile){file.remove("data/NOTenoughRAM.txt")}

  # geo dataset names
  datasets <- stack(paths)
  
  # load each dataset
  apply(datasets, 1, function(x){
    # find information regarding the database
    info <- database[[ids[[x[2]]]$id]]
    
    # CHeck if we need to distinguish between rna and protein data
    if(!is.null(info[[ftype]])){
      load_path(path=x[1], info=info[[ftype]], ftype=ftype) 
    }else{
      load_path(path=x[1], info=info, ftype=ftype) 
    }
  })
  
  return(list.files(paste0("data/processed/names/", ftype)))
}
