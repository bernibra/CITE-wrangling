# Write file with warnings for low RAM
write_warning_file <- function(scelist, filename){
  if (!file.exists("./data/NOTenoughRAM.txt")){
    
    write("# The following files were not fully processed because you don't have enough RAM in the current machine.",file="./data/NOTenoughRAM.txt",append=TRUE)
    write("# Nevetherless, some could be accounted for when building the name dictionaries.",file="./data/NOTenoughRAM.txt",append=TRUE)
    write("file,accounted",file="./data/NOTenoughRAM.txt",append=TRUE)
  }
  
  # Save the reformatted data as an rds file
  if(is.null(scelist$sce)){
    accounted <- ifelse(!is.null(scelist$colnames), "T", "F")
    # Not enough RAM to read this matrix
    write(paste(c(filename, accounted), collapse = ","),file="./data/NOTenoughRAM.txt",append=TRUE)
  }
  
  return(0)  
}

# Look for relevant filenames in directory
select_relevant_files <- function(filenames, info){
  
  # If there is only one file, then there is no problem
  if (length(filenames)==1){
    return(filenames)
  }
  
  # The mtx class can be tricky because the files don't always have an .mtx extension
  if(!is.null(info$class)){
    if(info$class=="mtx"){
      return(filenames[grepl(info$replace, base::basename(filenames))])
    }
  }

  # Files that have the following extensions are generally the main files
  filenames_ <- grepl(".rds$|.Rds$|.rds.gz$|.Rds.gz$|.mtx.gz$|.mtx$|.h5.gz$|.h5$", filenames)
  if ( any(filenames_) ){
    filenames <-  filenames[filenames_]
  }

  # The keywords describe proteins, RNA or HTOs generally
  ifelse(!(is.null(info$keyword)), 
          return(filenames[grepl(info$keyword, base::basename(filenames))]), 
          return(filenames))
}

# Load a single geo raw dataset
load_path <- function(path, info, ftype="protein", id="id", RAMlimit=T){
  # Start the processing of files
  message("processing data for: ", id)

  # Find all raw files
  filenames <- list.files(path, full.names = T)
  
  browser()
  # Untar if necessary
  if (length(filenames)==1 & all(grepl(".tar.gz$|.tar$", filenames))){
    filenames <- untar_folder(filenames)
  }
  
  # Unzip if necessary
  if (length(filenames)==1 & all(grepl(".zip$", filenames))){
    filenames <- decompress_zipfile(file = base::basename(filenames), directory = base::dirname(filenames))
  }

  # Dealing with multiple files if possible
  filenames <- select_relevant_files(filenames = filenames, info = info)
  
  # Create experiment folder
  dir.create(file.path("data/processed/sce-objects/", id), showWarnings = FALSE)

  experimentf <- file.path("data/processed/sce-objects/", id, ftype)
  dir.create(experimentf, showWarnings = FALSE)
  
  # Loop over files
  for (idx in 1:length(filenames)){

    rdir <- experimentf %>% 
      paste(., paste(basename(dirname(filenames[[idx]])), strsplit(basename(filenames[[idx]]), split = "\\.")[[1]][1], sep="-"), sep="/")
    rdir <- file.path(dirname(rdir), paste0(id, "-", basename(rdir)))

    rdir_ <- file.path("data/processed/names", ftype)

    # Check that the files have not been processed as HDF5 already
    fname <- define_processed_name(dirname(rdir), info$sample_groups, id)$path
    processed <- all(dir.exists(fname))

    # Process raw data and save as SingleCellExperiment class if not done already
    if(!file.exists(rdir) & !file.exists(paste0(rdir, ".rds")) & !processed){
      
      # Progress message
      message("processing ", ftype," data for ", basename(filenames[idx]))
      
      # Check if we can actually load the document
      shouldi <- should_i_load_this(filenames[idx], RAMlimit=RAMlimit)
        
      # Define class
      filename <- structure(shouldi$filename, class=info$class)

      # Read raw data and turn into SingleCellExperiment
      if(shouldi$shouldi){
        # Create Single Cell Experiment
        sce <- read_raw(filename, info)
      }else{
        # get column and row names at least
        sce <- get_row_column(filename)
      }

      # If the dataset has a dictionary, use it to rename the features
      if(!is.null(info$dictionary) & !is.null(sce$rownames)){
        sce$rownames <- rename_features(features=sce$rownames, dictionary=file.path(path, info$dictionary$file),
                                 key=info$dictionary$key,
                                 value=info$dictionary$value)
      }
      
      # Save the reformatted data as an rds file or HDF5 depending on whether or not samples are together
      if(!is.null(sce$sce)){
        if(ifelse(is.null(info$separate_samples), FALSE, info$separate_samples)){
          # Save object as rds
          saveRDS(object = sce$sce, file = paste0(rdir, ".rds"))
        }else{
          # Save object as HDF5
          HDF5Array::saveHDF5SummarizedExperiment(x = sce$sce, dir = rdir, verbose = T, replace = T)
        }
      }

      # Find row and column names
      if(!is.null(sce$colnames)){saveRDS(object = sce$colnames, file = file.path(rdir_, paste0("cells_", basename(rdir))))}
      if(!is.null(sce$rownames)){saveRDS(object = sce$rownames, file = file.path(rdir_, paste0("features_", basename(rdir))))}

      # Write Warning file if necessary
      write_warning_file(sce, filenames[idx])

      ## Compress files again to avoid using too much disc
      if((grepl(".csv$|.tsv$|.txt$", filename))){R.utils::gzip(filename)}
      
    }else{
      message("---> file already processed: ", basename(filenames[idx]))
      ## Compress files again to avoid using too much disc
      if((grepl(".csv$|.tsv$|.txt$", filenames[idx]))){R.utils::gzip(filenames[idx])}
      
    }
  }

  return(0)
}

# Format all datasets as SingleCellExperiments
load_db <- function(paths, ids, database, ftype="protein", rmfile=TRUE, RAMlimit=T){
  
  # remove info files if there
  if(file.exists("data/NOTenoughRAM.txt") & rmfile){file.remove("data/NOTenoughRAM.txt")}

  # geo dataset names
  datasets <- stack(paths)
  
  if(nrow(datasets)==0){
    return(c())
  }
  
  # load each dataset
  processed <- apply(datasets, 1, function(x){
    # find information regarding the database
    info <- database[[ids[[x[2]]]$id]]
    
    # Check if we need to distinguish between rna and protein data
    if(!is.null(info[[ftype]])){
      load_path(path=x[1], info=info[[ftype]], ftype=ftype, id=ids[[x[2]]]$id, RAMlimit=RAMlimit) 
    }else{
      load_path(path=x[1], info=info, ftype=ftype, id=ids[[x[2]]]$id, RAMlimit=RAMlimit) 
    }
    
    return(ids[[x[2]]]$id)
  })
  
  return(unique(processed))

}
