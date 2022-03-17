# Instructions for adding data to the repository
## Key files
Files `data/metadata.yalm` and `data/database.yalm` contain the metadata and the loading instructions for the data processing workflow.

### `metadata.yalm` file
This contains the information for downloading the raw data and the metadata for a given experiment. Each experiment is defined by the articles doi link acting as a unique identifier.  Every entry in the `metadata.yalm` can have the following keys:
- id: an alternative id for the databases (easier to read), often defined with the year of publication and an author's name.
- _setup_: this describes how to structre the directories. For geo databases, this needs to be `geo`; for any other this can either be NULL or a customized function (defined in `code/download_raw.R`).
- _download_: this key assigns a dowloading strategy for the raw data. For geo databases, this needs to be `geo`; for direct downloads, this needs to be `wget`; and one can have a customized class adding the corresponding method to `code/download_raw.R`. 

### `database.yalm` file
This contains the information for how to process the raw data. Each experiment is associated with the id and key from the `metadata.yalm` file. If both protein and rna data are processed the same way, the entry apply to both data types. If they are processed differently, the experiment should have a _protein_ part and a _rna_ part. Every entry in this file can have the following keys:
- _class_: this forces the file to be processed in a particular manner. One can customize these classes in `code/read_raw.R`.
- _transpose_: this indicates whether or not to transpose the matrix before converting to sce
- _coldata_: this signals what columns of the matrix need to be added as colData in the sce objects.
