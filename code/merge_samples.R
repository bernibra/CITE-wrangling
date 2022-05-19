merge_idx <- function(filenames){
  
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
    merge_idx(filenames)
  })
  
  return(list(a=paths, b=metadata))
  
}