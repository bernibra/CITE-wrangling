################################################
# Set of methods to perform QC on sce objects
################################################

qc_sce <- function(sce) UseMethod("qc_sce", sce)

# Basic QC
qc_sce.default <- function(sce){
  
  # No idea what to do here yet
  return(sce)
}