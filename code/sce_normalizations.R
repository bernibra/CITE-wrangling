################################################
# Set of methods to normalize sce objects
################################################

normalize_sce <- function(path) UseMethod("normalize_sce", path)

# Basic normalization
normalize_sce.default <- function(path){
  # Import object
  sce <- readRDS(path)

  # Compute size factors and normalize... this is just not right as this is designed for RNA data
  # DSB normalization to remove background noise
  # Accounting for samples is crucial
  sce <- logNormCounts(sce)
  
  return(sce)
}