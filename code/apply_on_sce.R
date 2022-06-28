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
  
  filename <- list.files(file.path(dirname(dirname(path)), "metadata"))
  
  if(is.null(alternative) | length(filename)==0){
    return(sce)
  }
  
  filename <- filename[gsub(alternative, filename)]
  
  if(length(filename)!=1){
    return(sce)
  }
  
  hto <- read_raw(filename, info=list())
  altExp(sce) <- hto
  
  return(sce)
}

