basic_formating <- function(features){
  # lowercase
  features %<>% tolower() %>% strsplit(split = "_|-|\\|")
  # remove special characters
  # find certain keywords
  return(features)
}

# Unify feature names
unify_features <- function(paths){
  # for (path in paths){
    # Read file
    path <- "features_GSE108313_GSM2895284_1.rds"
    features <- readRDS(path)
    
    # Basic name breakdown
    features <- basic_formating(features)
   
  # }
}

# Cross cell names across rna and protein datasets
check_cells <- function(){
  
}

# Unifying names across databases
unify_names <- function(ftype="protein"){
  paths <- list.files(file.path("data/processed/names/", ftype), full.names = T)
  
  features <- check_features(paths=paths[grepl("features_", paths)])
  
  cells <- check_cells(paths[grepl("cells_", paths)])
  
}