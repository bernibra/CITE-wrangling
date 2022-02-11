# Download raw data
get_file <- function(id, dest_dir, download_date = NULL){
  rdir <- file.path(dest_dir, id)
  if(!file.exists(file.path(rdir, id))){
    dir.create(rdir, showWarnings = FALSE)
    message("donwloading data on ", download_date)
    getGEO(id, destdir = rdir)
  } else {
    message("file already found")
    return(0)
  }
}

make_test <- function(){
  pdf("data/test_plot.pdf", width = 4, height = 4)
  plot(rnorm(1000, 0, 1))
  dev.off()
}
