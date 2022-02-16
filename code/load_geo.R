# Load a single geo raw dataset
load_geo_id <- function(paths, info){
  for(id in paths){
    if(id!="0"){
      if(length(list.files(id))>1){
        print("--------------------------")
        print(list.files(id, full.names = T))
      }
    }
  }
}

# Format all datasets as SingleCellExperiments
load_geo <- function(paths, ids){
  
  # geo dataset names
  datasets <- names(paths)
  
  # load each dataset
  lapply(datasets, function(x) load_geo_id(paths=paths[[x]], info=ids[[x]]))
  
}