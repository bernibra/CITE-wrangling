# CITE-wrangling

Basic workflow for the wrangling of CITE-seq data. A full list of the datasets used at the moment can be found [here](data/list-of-papers.csv).

### 1. Requirements

Check that the software and hardware requirements have been met.
* Docker 20.10
* At least 30GB free on disk
* A lot of RAM (I haven't estimated exactly how much but it should be more than 50GB)
* Stable internet connection (otherwise you won't be able to run the whole thing)

### 2. Clone the repo

Download or clone the repo: 
```
git clone https://github.com/bernibra/CITE-wrangling.git
```

### 3. Build Docker image and run container

Type the following commands in the working directory (you might need [sudo rights](https://docs.docker.com/engine/install/linux-postinstall/)):
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

If you want to run the pipline for a single experiment, you can do so specifying the id. For example, for Buus2021:

```
docker exec -u rstudio cite-wrangling-container make -C /home/rstudio/cite-wrangling id="Buus2021"
```

### 5. Other

_5.0. Using the [UNIL cluster](https://wiki.unil.ch/ci/books/service-de-calcul-haute-performance-%28hpc%29/page/how-to-access-the-clusters)_

to run the pipeline in the UNIL cluster, one cannot use Docker directly, but can use a singularity container instead. The file defining such a container is the `cite.def` (for more information see [link](https://wiki.unil.ch/ci/books/high-performance-computing-hpc/page/sandbox-containers)). The cluster at unil uses _slurm_, so one can run the pipeline with the singularity image built with `cite.def` by executing the file `main.sh`.

_5.1. Testing code_: 

you can edit or develop new code and test it in the docker container by adding the code to the directory (`./code/`), rebuilding the docker image (step 3), and accessing the container through your web browser at <yourhostip:28787> (`hostname -I` in the terminal to find your host ip). It might not work if you are connected to a vpn.

_5.2. Adding new datasets_:

new datasets can be added, but one needs to follow [certain instructions](data/README.md) to preserve the workflow.

_5.3. Potential problems_:
- if the internet connection is not stable, some of the datasets might have problems downloading. The automatically generated file `GEOrawDataNotFound.txt` reports on some of these problems. One possibility is to rerun the code. To do so, first delete the directory in `data/raw` for the corresponding id. Then, open and R session and run `drake::clean()` or delete the `.drake` directory. Then, one can simply execute the project workflow again (todo: simplify this so that drake identifies it; I belive `file_out()` will do the trick). That said, sometimes it's simply that the file does not exist (go figure!), in which case there is not much that the pipline can do. Maybe you should email the authors.
- if you have limited RAM, some of the datasets might have problems processing. The automatically generated file `NOTenoughRAM.txt` report on these problems. The RAM limitations can only be easily solved by using a machine with more RAM (or requesting additional RAM if running on a computer cluster). The only alternative is to split any big files into smaller ones (see an example of how to do this in function `split_big_file()` from `code/load_files.R`)
- Some datasets require manual downloading; this will be reported in `GEOrawDataNotFound.txt`. Additionally, inside the raw data folder for a given dataset, a `README` file is sometimes generated to indicate what files to download.

