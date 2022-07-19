# Instructions for adding data to the repository
## Key files
Files in `data/databases` contain the basic instructions to download, read, and process each dataset. Files in `data/xtra_metadata` provide additional metadata for each dataset.

### `data/databases` files
Each file provides instructions for a single dataset as a yaml file. Each dataset/experiment is defined by a unique identifier that defines in turn the name of the corresponding yaml file. The yaml file contains three main keys: download, load, and metadata. 
- _download_: this describes the instructions to download the raw data, containing the following sub-keys: 
  - _id_: the id for the databases (easier to read), often defined with the year of publication and an author's name, which also defines the file name.
  - _setup_: this describes how to structre the raw data directories. For geo databases, this should be `geo`; for any other this can either be NULL or a customized function (defined in `code/download_raw.R`).
  - _download_: this key assings a downloading strategy for the data. For [geo databases](databases/GSE108313.yaml), this can be `geo`; for [direct downloads](databases/Kotliarov2020.yaml), this should be `wget`, which will use a url to directly download any given file provided in the _wlink_ key; for any other this can be customized function (defined in `code/download_raw.R`; e.g. `array` for [arrayexpress downloads](databases/E-MTAB-10026.yaml)). For GEO, one can also directly copy the path to the desired files and use instead `wget`. 
  - _wlink_: list of links for direct download. These should be classified under three additional sub-keys: _protein_ (for protein data); _rna_ (for rna data) and _other_ (for metadata). If only the key _protein_ is provided, the pipline assumes that both rna and protein data come in the same file. See an example of the use of this key in file `data/databases/Shangguan2021.yaml`
  - _fname_: list of names for the direct downloads. This key is analogous to the _wlink_ and simply assigns a name to a given downloaded file.
- _load_: this describes the instructions to process the raw data. If both protein and rna data are processed the same way, the entries/sub-keys apply to both data types. If they are processed differently, the experiment should have a _protein_ and a _rna_ sub-keys defining each process. Then every file can have the following additional keys:
  - _class_: this forces the file to be processed in a particular manner. One can customize these classes in `code/read_raw.R`.
  - _transpose_: this indicates whether or not to transpose the matrix before converting to sce (for those cases where the raw data is a read counts matrix).
  - _coldata_: this signals what columns of the matrix need to be added as colData in the sce objects. Added as a list of columns.
  - _separate\_samples_: it indicates whether or not the samples come in separate files or not. It is important because it will then be used to combine them into a single SingleCellExperiment.
  - _sample\_groups_: this entry indicates whether or not one needs to separate samples into different groups (important when a given experiment have multiple samples and those have different number of proteins expressed). The entry should contain a list of keywords used to separate the samples.
- _metadata_: this entry provides basic metadata for each file. Every file can have the following additional self-explanatory keys: _doi_, _description_, _tissue_, _species_, and _alias_.

### `data/xtra_metadata` files
For every experiment/dataset one can define additional metadata, often defining additional information regarding the samples. For example, patient information or treatment. The format for these files is flexible, but one should only define one csv file per dataset (with the id of the dataset as the file name).
