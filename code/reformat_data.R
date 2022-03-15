#####################################################
# Different ways to reformat the data
#####################################################

reformat_protein <- function(pnames, ids){
  for (pname in unique(pnames$new)){
    dbs <- gsub("features_", "data/processed/protein-data-clean/", pnames$db[pnames$new==pname])
    protein <- pnames$original[pnames$new==pname]
    
    plist <- sapply(1:length(dbs), function(idx){
      sce <- readRDS(dbs[idx])[protein[idx],]
    })
  }
}