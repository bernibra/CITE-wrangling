sce_move_to_coldata <- function(sce, row){
  
  if(is.null(row)){
    return(sce)
  }
  
  # Are there any funky rows that need to be added as coldata
  assay_names <- names(assays(sce))
  
  for(x in row){
    for(y in assay_names){
      new_coldata <- paste0(x, y)
      condition <- rownames(sce) %in% x
      if (any(condition)){
        colData(sce)[new_coldata] <- assay(sce, y)[condition,]
      }
    }
  }
  
  condition <- rownames(sce) %in% row
  sce <- sce[!condition, ]
  
  return(sce)
}

add_alt_exp <- function(sce, path, alternative=NULL){
  
  # Extract SingleCellExperiment
  sce <- sce$sce
  
  # Find metadata
  filename <- list.files(file.path(dirname(dirname(path)), "metadata"), full.names = T)

  if(is.null(alternative) | length(filename)==0){
    return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
  }
  
  filename <- filename[grepl(alternative, filename)]

  if(length(filename)!=1){
    return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
  }

  # Load hto
  hto <- read_raw(filename, info=list())$sce

  # Match columns
  joint.bcs <- intersect(colnames(sce), colnames(hto))
  sce <- sce[,joint.bcs]
  hto <- hto[,joint.bcs]
  
  # Add as alternative experiment
  altExp(sce, "hto") <- hto
  
  return(list(sce=sce, rownames=rownames(sce), colnames=colnames(sce)))
}

add_metadata <- function(filenames, metadata, args=NULL){
  if(!is.null(args)){
    metadata <- metadata[names(metadata)[args]]
  }
  
  paths <- lapply(filenames, function(x){
    # Find id
    id <- stringr::str_split(pattern = "_", string = basename(x))[[1]][1]
    print(id)
    
    # Check if we need to process it
    if(!(id %in% names(metadata))){
      return(x)
    }
    
    # Create empty sample information
    sample_information <- tibble::tibble()
    
    # Load sce
    sce <- HDF5Array::loadHDF5SummarizedExperiment(x)
    
    # Check if there is any sample information
    extra <- paste0("data/xtra_metadata/", id, ".csv")
    if(file.exists(extra)){
      sample_information <- readr::read_delim(extra)
    }
    
    # Add sample information to metadata
    prepare_metadata <- metadata[[id]]
    prepare_metadata$sample_information <- sample_information
    
    # Check if sce metadata needs to be changed
    if(!identical(metadata(sce), prepare_metadata)){
      metadata(sce) <- prepare_metadata
      HDF5Array::quickResaveHDF5SummarizedExperiment(sce, verbose = T)
    }
    
    return(x)
  })
  return(paths)
}

