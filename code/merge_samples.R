merge_idx <- function(filenames, dir){
  
  base_sce <- readRDS(filenames[1])
  
  if(length(filenames)>1){
    for(idx in 2:length(filenames)){
      sce <- readRDS(filenames[idx])
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
