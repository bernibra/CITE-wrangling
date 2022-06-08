add_NAS <- function(coldata1, coldata2){
  if(any(!(names(coldata2) %in% names(coldata1)))){
    coldata1[names(coldata2)[!(names(coldata2) %in% names(coldata1))]] <- NA
  }
  if(any(!(names(coldata1) %in% names(coldata2)))){
    coldata2[names(coldata1)[!(names(coldata1) %in% names(coldata2))]] <- NA
  }
  return(list(first=coldata1, second=coldata2))
}

merge_idx <- function(filenames, dir){
  
  base_sce <- readRDS(filenames[1])
  if(!all("SAMPLE_ID" %in% names(colData(base_sce)))){
    colData(base_sce)$SAMPLE_ID <- basename(filenames[1])
  }
  
  if(length(filenames)>1){
    for(idx in 2:length(filenames)){
      sce <- readRDS(filenames[idx])
      if(!all("SAMPLE_ID" %in% names(colData(sce)))){
        colData(sce)$SAMPLE_ID <- basename(filenames[idx])
      }
      
      # Add NA to missing columns in colData
      coldata <- add_NAS(colData(base_sce), colData(sce))
      colData(base_sce) <- coldata$first
      colData(sce) <- coldata$second
      
      # Merge SCE
      base_sce <- cbind(base_sce, sce)
    }
  }

  # Write h5 file
  HDF5Array::saveHDF5SummarizedExperiment(x = base_sce, dir = dir)

  # Remove rds files
  sapply(filenames, unlink)
}

# Format all datasets as SingleCellExperiments
merge_samples <- function(paths, files, metadata, ftype="protein", overwrite=TRUE){
  
  files_ <- basename(files)
  
  newsce <- lapply(names(paths), function(x){
    # Find id
    idx <- metadata[[x]]$id
    
    # Filter by id
    filenames <- files[grepl(idx, files_)]
    
    # Merge sce and save as HDF5 file
    if(length(filenames)>0){
      merge_idx(filenames, dir=file.path(dirname(filenames[1]), idx))
    }
  })
  
  return(list(a=paths, b=metadata))
  
}
