
rootdir <- "../data/processed/names/abnames-proteins/"
dir.create(rootdir, showWarnings = F)

mainfolders <- list.dirs("../data/processed/sce-objects/", full.names = T, recursive = F)

for (i in mainfolders){
  
  folders <- list.dirs(file.path(i, "protein"), full.names = T, recursive = F)
  dir.create(paste0(rootdir, basename(i)), showWarnings = F)
  
  for( j in folders){
    
    file <- paste0(file.path(rootdir, basename(i), basename(j)), ".rds")
    
    if(!file.exists(file)){
      
      sce <- HDF5Array::loadHDF5SummarizedExperiment(j)
      saveRDS(rownames(sce), file = file)
      
    }
  }
}

