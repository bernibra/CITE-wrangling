basic_formating <- function(features, ftype, keywords=c("control", "protein", "pabo", "adt")){
  
  slice <- grepl("protein|pAbO", features$original)
  if(sum(slice)>2){
    if(ftype=="protein"){
      features <- features[slice,]
    }else{
      features <- features[!slice,]
    }
  }
  
  ####
  # Provisional patch, I need to fix this in the data processing
  features <- features[!(features$original %>% stringr::str_detect("^ENSG*")),]
  
  ####
  
  # drop anything that resembles a sequence, is simply a number or is one of the keywords
  features$clean <- features$original %>%
    tolower() %>%
    # stringr::str_replace(stringr::regex("(?>nm)(.*)(?=\\|)"), "|") %>%
    strsplit(split = "\\.|_|-|\\|") %>%
      sapply(function(x) 
        paste0(
          x[!(!grepl("[^acgt]", x) & grepl("^.{3,}$", x))  & !(x %in% keywords)],
          collapse = " ")
      )
  # & !grepl("^\\d$", x)
  
  return(features)
}

# Unify feature names
unify_features <- function(paths, ftype){
  
  df <- list()
  
  pb = txtProgressBar(min = 0, max = length(paths), initial = 0, style = 2) 
  
  for (idx in 1:length(paths)){
    path <- paths[idx]
    
    # Start progress bar
    setTxtProgressBar(pb,idx)
    
    # Read file
    features <- data.frame(db=basename(path), original=readRDS(path))
    
    # Basic name breakdown
    features <- basic_formating(features, ftype=ftype)
  
    # Add to dictionary
    df[[idx]] <- features
  }
  
  # Close progress bar
  close(pb)
  
  dictionary <- do.call("rbind",df)
}

# Cross cell names across rna and protein datasets
check_cells <- function(){
  
}

# Unifying names across databases
unify_names <- function(ftype="protein"){
  paths <- list.files(file.path("data/processed/names/", ftype), full.names = T)
  
  features <- check_features(paths=paths[grepl("features_", paths)], ftype=ftype)
  
  cells <- check_cells(paths[grepl("cells_", paths)])
  
}