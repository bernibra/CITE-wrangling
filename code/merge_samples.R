add_NAS <- function(coldata1, coldata2){
  if(any(!(names(coldata2) %in% names(coldata1)))){
    coldata1[names(coldata2)[!(names(coldata2) %in% names(coldata1))]] <- NA
  }
  if(any(!(names(coldata1) %in% names(coldata2)))){
    coldata2[names(coldata1)[!(names(coldata1) %in% names(coldata2))]] <- NA
  }
  return(list(first=coldata1, second=coldata2))
}

merge_idx <- function(filenames, dir, overwrite){
  
  base_sce <- readRDS(filenames[1])
  if(!all("SAMPLE_ID" %in% names(colData(base_sce)))){
    colData(base_sce)$SAMPLE_ID <- 1
  }
  colData(base_sce)$FILE_ID <- basename(filenames[1])
  
  if(length(filenames)>1){
    for(idx in 2:length(filenames)){
      print(filenames[idx])
      sce <- readRDS(filenames[idx])
      if(!all("SAMPLE_ID" %in% names(colData(sce)))){
        colData(sce)$SAMPLE_ID <- idx
      }
      colData(sce)$FILE_ID <- basename(filenames[idx])
      
      # Add NA to missing columns in colData
      coldata <- add_NAS(colData(base_sce), colData(sce))
      colData(base_sce) <- coldata$first
      colData(sce) <- coldata$second
      
      # Merge SCE
      base_sce <- cbind(base_sce, sce)
    }
  }

  # Write h5 file
  HDF5Array::saveHDF5SummarizedExperiment(x = base_sce, dir = dir, verbose = T, replace = T)

  # Remove rds files
  if(overwrite){
    sapply(filenames, unlink)
  }
  return(dir)
}

# Format all datasets as SingleCellExperiments
merge_samples <- function(paths, files, metadata, database, ftype="protein", overwrite=TRUE){
  
  dirs <- lapply(files, function(idx){
    # Files that are not merged
    rdsfiles <- list.files(file.path("data/processed/sce-objects/", idx,ftype), full.names = T)
    hdf5files <- list.dirs(file.path("data/processed/sce-objects/", idx,ftype), full.names = T, recursive = F)
    
    # Filter by id
    filenames <- rdsfiles[grepl(".rds$", rdsfiles)]
    
    # Get info
    info <- database[[idx]]
    
    # Check if we need to distinguish between rna and protein data
    if(!is.null(info[[ftype]])){
      info <- info[[ftype]] 
    }

    # Merge sce and save as HDF5 file
    if(length(filenames)>0){
  
      sample_groups <- define_processed_name(folder=dirname(filenames[1]), sample_groups = info$sample_groups, id = idx)
      
      dirs <- apply(sample_groups, 1, function(y) {
        files <- filenames[grepl(y[1], basename(filenames))]
        if(length(files)>0){
          merge_idx(files, dir=y[2], overwrite)
          return(y[2])
        }
      })
    }else{
      dirs <- c()
    }
    
    # Collect all the resulting files
    files <- c(hdf5files, unlist(dirs))
    names(files) <- NULL
    return(files)
  })
  
  return(unlist(dirs))
  
}
