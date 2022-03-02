basic_formating <- function(features, ftype, keywords=c("protein", "adt"), path=NULL){
  
  slice <- grepl("protein|pAbO", features$original)
  if(sum(slice)>2){
    if(ftype=="protein"){
      features <- features[slice,]
    }else{
      features <- features[!slice,]
    }
  }
  
  ####
  # Provisional patch, I need to find a better way to filter those
  features <- features[!(features$original %>% stringr::str_detect("^ENSG*")),]
  features <- features[!(features$original %>% stringr::str_detect("^TotalSeq*")),]
  if(nrow(features)==0){stop("Oups... it seems no protein names were found in the following database... suspicious:\n", path)}
  ####
  
  # drop anything that resembles a sequence, is simply a number or is one of the keywords
  features$clean <- features$original %>%
    tolower() %>%
    # Deal with hyphens... in a weird but effective way - Part 1
    stringr::str_replace_all(pattern = "-", replacement = "\\|-\\|", string = .) %>%
    # Split string
    strsplit(split = "/|,|\\(|\\)|\\.|_|\\|| ") %>%
    # Remove seq and words in keyword set. Clean up spaces as well
    sapply(function(x){
          y <- x[!(!grepl("[^acgt]", x) & grepl("^.{6,}$", x)) & !(x %in% keywords)] %>% 
            stringr::str_trim() %>%
            gsub(pattern = "\\s+", replacement = " ", x = .)
          paste0(y, collapse = " ")}
    ) %>%
    # Deal with hyphens... in a weird but effective way - Part 2
    stringr::str_replace_all(pattern = " - ", replacement = "-", string = .) %>%
    stringr::str_replace_all(pattern = " -$|^- ", replacement = "", string = .) %>%
    # Other clean-ups
    stringr::str_replace_all(pattern = "a b c$|a-b-c$|a b c |a-b-c ", replacement = "-abc ", string = .) %>%
    stringr::str_trim() %>%
    # Deal with hyphens... in a weird but effective way - Part 3
    stringr::str_replace_all(pattern = "--", replacement = "-", string = .) %>%
    strsplit(split = " ") %>% sapply(function(x) x[!grepl("^\\d$", x)] %>% unique() %>% paste(collapse = " ")) %>%
    stringr::str_replace_all(pattern = "-", replacement = " ", string = .)
  
  # Find common words across a given dataset
  common <- features$clean %>%
    strsplit(split = " ") %>%
    unlist() %>%
    unique() %>%
    sapply(function(x) all(grepl(pattern = paste0("\\<",x, "\\>"), x = features$clean)), USE.NAMES = T) %>%
    names(.)[.]
  
  if (length(common)>0 & length(unique(features$clean))>1 ){
    features$clean %<>% stringr::str_remove_all(pattern = paste(common, collapse = "|")) %>% stringr::str_trim()
  }
  
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
    features <- basic_formating(features, ftype=ftype, path=path)
  
    # Add to dictionary
    df[[idx]] <- features
    
  }
  
  # Close progress bar
  close(pb)
  
  dictionary <- do.call("rbind",df) %>% group_by(clean) %>% mutate(id=cur_group_id())
  
  # Quick and dirty trick
  # Compute dissimilarity of every pair of unique "sentences" by word
  unic_val <- dictionary %>% dplyr::select(clean, id) %>% distinct(clean, id) %>% arrange(id) %>% pull(clean)
  n <- length(unic_val)
  diss <- diag(0, nrow = n, ncol = n)
  
  pairs <- combn(1:n, 2)
  for(i in 1:ncol(pairs)){
    x <- strsplit(split = " ", unic_val[pairs[1,i]])[[1]]
    y <- strsplit(split = " ", unic_val[pairs[2,i]])[[1]]
    d <- length(intersect(x,y))/min(c(length(x), length(y)))
    diss[pairs[1,i], pairs[2,i]] <- d
    diss[pairs[2,i], pairs[1,i]] <- d
  }
  
  # starting with the longer names, we find those perfect matches across databases
  dictionary %<>% mutate(len=length(strsplit(split = " ", clean)[[1]])) %>% arrange(desc(len))
  dictionary$genus <- sapply(1:nrow(dictionary), function(i){
    x <- dictionary[i, ]
    
    y <- which(diss[x$id,]>0)
    z <- !(y %in% dictionary$id[dictionary$db==x$db])
    if (any(z)){
      y <- y[which.max(diss[x$id,y[z]])]
      value <- unic_val[y]
    }else{
      value <- x$clean
    }
    value
  })
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