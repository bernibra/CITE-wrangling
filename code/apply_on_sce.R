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

add_metadata <- function(filename, info){
  
}

