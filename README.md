# CITE-wrangling

Basic workflow for the wrangling of CITE-seq data

### 1. Requirements

Check that the software and hardware requirements have been met.
* Docker 20.10
* 0.76 GB free on disk
* Stable internet connection (otherwise you won't be able to run the whole thing)

### 2. Clone the repo

Download or clone the repo: 
```
git clone https://github.com/bernibra/CITE-wrangling.git
```

### 3. Build Docker image and run container

Type the following commands in the working directory (you might need sudo rights):
```
docker build --rm --force-rm -t cite-wrangling .
docker run -d -e DISABLE_AUTH=true --rm -p 28787:8787 -v $PWD:/home/rstudio/cite-wrangling -e USERID="$(echo $UID)" -e GROUPID="$(echo $GID)" --name cite-wrangling-container cite-wrangling
```
_Building the docker image might take a bit of time, so go grab a coffee in the mean time_

### 4. Download and process the data

You can do this by running the makefile:
```
docker exec -u rstudio cite-wrangling-container make -C /home/rstudio/cite-wrangling
```
_The first time runing this might take some time again, you might want to run it over night_

### 5. Other
_Testing code_:
> you can edit or develop new code and test it in the docker container by adding the code to the directory (`./code/`), rebuilding the docker image (step 3), and accessing the container through your web browser at <yourhostip:28787> (`hostname -I` in the terminal to find your host ip). It might not work if you are connected to a vpn.

_Adding new datasets_:
> new datasets can be added, but one needs to follow [certain instructions](data/README.md) to preserve the workflow.

_Potential problems_:
> if the internet connection is not stable, some of the datasets might have problems downloading. The automatically generated file `GEOrawDataNotFound.txt` reports on these problems. One possibility is to rerun the code. To do so, first delete the directory in `data/raw` for the corresponding id. Then, open and R session and run `drake::clear()` or delete the `.drake` directory. Then, one can simply execute the project workflow again (todo: simplify this so that drake identifies this; I belive file\_out will do the trick).
> if you have limited RAM, some of the datasets might have problems processing. The automatically generated file `NOTenoughRAM.txt` report on these problems. The RAM limitations can only be easily solved by using a machine with more RAM (or requesting additional RAM if running on a computer cluster). The only alternative is to split any big files into smaller ones (see an example of how to do this in function `split\_big\_file` from `code/load\_files.R`)

