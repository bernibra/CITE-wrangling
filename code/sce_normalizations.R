# Basic normalization
normalize_sce <- function(path){
  # Import object
  sce <- readRDS(path)

  # Compute size factors and normalize
  sce <- logNormCounts(sce)
  
  return(sce)
}