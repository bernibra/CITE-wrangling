# Instructions for adding data to the repository
## Key files
Files `data/metadata.yalm` and `data/database.yalm` contain the metadata and the loading instructions for the data processing workflow.

### `metadata.yalm` file
This contains the information for downloading the raw data and the metadata for a given experiment. Each experiment is defined by the articles doi link acting as a unique identifier.  Every entry in the `metadata.yalm` can have the following keys:
- id: an alternative id for the databases (easier to read), often defined with the year of publication and an author's name.
- _setup_: this describes how to structre the directories. For geo databases, this needs to be `geo`; for any other this can either be NULL or a customized function (defined in `code/download_raw.R`).
- _download_: this key assigns a dowloading strategy for the raw data. For geo databases, this needs to be `geo`; for direct downloads, this needs to be `wget`; and one can have a customized class adding the corresponding method to `code/download_raw.R`. 
