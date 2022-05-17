# Format all datasets as SingleCellExperiments
merge_samples <- function(paths, database, ftype="protein", overwrite=TRUE){
  
  # geo dataset names
  # datasets <- stack(paths)
  
  return(list(a=paths, b=database))
  
  # # load each dataset
  # apply(datasets, 1, function(x){
  #   
  #   # find information regarding the database
  #   info <- database[[ids[[x[2]]]$id]]
  #   
  #   # Check if we need to distinguish between rna and protein data
  #   if(!is.null(info[[ftype]])){
  #     load_path(path=x[1], info=info[[ftype]], ftype=ftype) 
  #   }else{
  #     load_path(path=x[1], info=info, ftype=ftype) 
  #   }
  # })
  
  # return(list.files(paste0("data/processed/names/", ftype)))
}