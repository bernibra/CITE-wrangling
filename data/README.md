# Instructions for adding data to the repository
## Key files
Files in `data/databases` contain the basic instructions to download, read, and process each dataset. Files in `data/xtra_metadata` provide additional metadata for each dataset.

### `data/databases` files
Each file provides instructions for a single dataset as a yaml file. Each dataset/experiment is defined by a unique identifier that defines in turn the name of the corresponding yaml file. The yaml file contains three main keys: download, load, and metadata. 
- _download_: this describes the instructions to download the raw data, containing the following sub-keys: 
  - _id_: the id for the databases (easier to read), often defined with the year of publication and an author's name, which also defines the file name.
  - _setup_: this describes how to structre the raw data directories. For geo databases, this needs to be `geo`; for any other this can either be NULL or a customized function (defined in `code/download_raw.R`).
  - _download_: this key assigns a dowloading strategy for the raw data. For geo databases, this needs can be `geo`; for direct downloads, this needs to be `wget`; and one can have a customized class adding the corresponding method to `code/download_raw.R`. 
- _load_: this describes the instructions to process the raw data. If both protein and rna data are processed the same way, the entries/sub-keys apply to both data types. If they are processed differently, the experiment should have a _protein_ and a _rna_ sub-keys defining each process. Then every file can have the following additional keys:
  - _class_: this forces the file to be processed in a particular manner. One can customize these classes in `code/read_raw.R`.
  - _transpose_: this indicates whether or not to transpose the matrix before converting to sce (for those cases where the raw data is a read counts matrix).
  - _coldata_: this signals what columns of the matrix need to be added as colData in the sce objects. Added as a list of columns.
  - _separate\_samples_: it indicates whether or not the samples come in separate files or not. It is important because it will then be used to combine them into a single SingleCellExperiment.
  - _sample\_groups_: this entry indicates whether or not one needs to separate samples into different groups (important when a given experiment have multiple samples and those have different number of proteins expressed). The entry should contain a list of keywords used to separate the samples.
- _metadata_: this entry provides basic metadata for each file. Every file can have the following additional self-explanatory keys: _doi_, _description_, _tissue_, _species_, and _alias_.

### `data/xtra_metadata` files
For every experiment/dataset one can define additional metadata, often defining additional information regarding the samples. For example, patient information or treatment. The format for these files is flexible, but one should only define one csv file per dataset (with the id of the dataset as the file name).
