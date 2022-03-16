#####################################################
# Different ways to reformat the data
#####################################################

reformat_protein <- function(pnames, ids){
  dir.create("data/processed/protein-data-shiny")
  
  pb = txtProgressBar(min = 0, max = length(unique(pnames$new)), initial = 0, style = 2)
  i <- 1
  for (pname in unique(pnames$new)){
    
    setTxtProgressBar(pb,i)
    
    dbs <- gsub("features_", "data/processed/protein-data/", pnames$db[pnames$new==pname])
    protein <- pnames$original[pnames$new==pname]
    
    plist <- lapply(1:length(dbs), function(idx){
      sce <- readRDS(dbs[idx])[protein[idx],]
      if(any(is.na(counts(sce)))){
        return(NULL)
      }
      if(!is.null(colData(sce)$SAMPLE_ID)){
        plist_ <- lapply(unique(colData(sce)$SAMPLE_ID), function(idy){
          values <- counts(sce[,as.character(colData(sce)$SAMPLE_ID)==as.character(idy)])
          df <- ggplot_build(ggplot(data.frame(y=values[1,]), aes(x = y))+geom_density())$data[[1]][,c("x", "y")]
          df$SAMPLE_ID <- idy
          df$DB <- dbs[idx]
          return(df)
        })
        return(plist_)
      }
      values <- counts(sce)
      df <- ggplot_build(ggplot(data.frame(y=values[1,]), aes(x = y))+geom_density())$data[[1]][,c("x", "y")]
      df$SAMPLE_ID <- dbs[idx]
      df$DB <- dbs[idx]
      return(df)
    })
    
    if(any(sapply(plist, is.list))){
      plist_ <- unlist(plist,recursive = F)
    }
    
    saveRDS(plist, file = file.path("data/processed/protein-data-shiny/", paste0(gsub(" ", "-", pname), ".rds")))
    i <- i+1
  }
  close(pb)
  
}
