# Useful information for demultiplexing:
# http://bioconductor.org/books/3.14/OSCA.advanced/droplet-processing.html
# https://satijalab.org/seurat/archive/v3.0/hashing_vignette.html

demultiplex_sce <- function(sce, hto, FDR_threshold=0.001, by.rank=12000, lower=10){
  joint.bcs <- intersect(colnames(sce), colnames(hto))
  sce_ <- sce[,joint.bcs]
  hto_ <- hto[,joint.bcs]
  
  altExp(sce_, "hto") <- hto_
  
  is.cell <- DropletUtils::emptyDrops(counts(altExp(sce_)), by.rank=by.rank, lower=10)$FDR <= FDR_threshold
  hto.mat <- counts(altExp(sce_))[,which(is.cell)]
  hash.stats <- DropletUtils::hashedDrops(hto.mat)
  return(hash.stats)
}