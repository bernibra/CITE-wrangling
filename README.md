# CITE-wrangling

Basic workflow for the wrangling of CITE-seq data

### 1. Requirements

Check that the software and hardware requirements have been met.
* Docker 20.10
* X GB free on disk

### 2. Clone the repo

Download or clone the repo: 
```
git clone https://github.com/bernibra/CITE-wrangling.git
```

### 3. Build Docker image and run container
Type the following commands in the working directory (you might need sudo rights):
```
docker build -t cite-wrangling
docker run -d -e DISABLE_AUTH=true --rm -p 28787:8787 -name cite-wrangling-container cite-wrangling
```

### 4. Download and process the data
You can do this by running the makefile:
