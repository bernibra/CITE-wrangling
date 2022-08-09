# Instructions for adding data to the repository
## Key files
Files in `data/databases` contain the basic instructions to download, read, and process each dataset. Files in `data/xtra_metadata` provide additional metadata for each dataset.

### `data/databases` files
Each file provides instructions for a single dataset as a yaml file. Each dataset/experiment is defined by a unique identifier that defines in turn the name of the corresponding yaml file. The yaml file contains three main keys: download, load, and metadata. 
- _download_: this describes the instructions to download the raw data, containing the following sub-keys: 
  - _id_: the id for the databases (easier to read), often defined with the year of publication and an author's name, which also defines the file name.
  - _setup_: this describes how to structre the raw data directories. For geo databases, this should be `geo`; for any other this can either be NULL or a customized function (defined in `code/download_raw.R`).
  - _download_: this key assings a downloading strategy for the data. For [geo databases](databases/GSE108313.yaml), this can be `geo`; for [direct downloads](databases/Kotliarov2020.yaml), this should be `wget`, which will use a url to directly download any given file provided in the _wlink_ key; for any other this can be customized function (defined in `code/download_raw.R`; e.g. `array` for [arrayexpress downloads](databases/E-MTAB-10026.yaml)). For GEO, one can also directly copy the path to the desired files and use instead `wget`. If it is not possible to download the data directly, one should use `impossible` and provide a _source_ key (see below). 
  - _wlink_: list of links for direct download. These should be classified under three additional sub-keys: _protein_ (for protein data); _rna_ (for rna data) and _other_ (for metadata). If only the key _protein_ is provided, the pipline assumes that both rna and protein data come in the same file. See an example of the use of this key in file `data/databases/Shangguan2021.yaml`
  - _fname_: list of names for the direct downloads. This key is analogous to the _wlink_ and simply assigns a name to a given downloaded file.
  - _description_ and _keyword_: some GEO datasets come with many experiments, each associated with a GEO accession key. To select the right experiments, one can do so defining _description_ and _keyword_. Given the metadata of a GEO database, _description_ will point at a metadata coloumn, and _keyword_ will pattern match one or more experiments using regular expressions. Different keywords can be set for RNA and protein data using the sub-keys: _rna_ and _protein_. See an example of this for the [GSE156478](databases/GSE156478.yaml) experiment.
  - _source_: if files need to be downloaded manually for some reason, one can add the source url here. This should come with _download_ defined as impossible (see [PRJEB40448](databases/PRJEB40448.yaml)).
- _load_: this describes the instructions to process the raw data. If both protein and rna data are processed the same way, the entries/sub-keys apply to both data types. If they are processed differently, the experiment should have a _protein_ and a _rna_ sub-keys defining each process. Then every file can have the following additional keys:
  - _class_: this forces the file to be processed in a particular manner. One can customize these classes in `code/read_raw.R`.
  - _transpose_: this indicates whether or not to transpose the matrix before converting to sce (for those cases where the raw data is a read counts matrix).
  - _coldata_: this signals what columns of the matrix need to be added as colData in the sce objects. Added as a list of columns.
  - _separate\_samples_: it indicates whether or not the samples come in separate files or not. It is important because it will then be used to combine them into a single SingleCellExperiment.
  - _sample\_groups_: this entry indicates whether or not one needs to separate samples into different groups (important when a given experiment have multiple samples and those have different number of proteins expressed). The entry should contain a list of keywords used to separate the samples.
  - _keyword_: if the wlink provided, the GEO id or the ArrayExpress id downloads multiple files at once, the keyword
is used to select the right ones for processing. This key has two sub-keys&mdash;_protein_ and _rna_&mdash;that allow
for a keyword for each type of single-cell data. This is particularly useful when, for example, a GEO id downloads tog
ether RNA and protein data. See an example of this for the [GSE152469](databases/GSE152469.yaml) experiment.
- _metadata_: this entry provides basic metadata for each file. Every file can have the following additional self-explanatory keys: _doi_, _description_, _tissue_, _species_, and _alias_.

### `data/xtra_metadata` files
For every experiment/dataset one can define additional metadata, often defining additional information regarding the samples. For example, patient information or treatment. The format for these files is flexible, but one should only define one csv file per dataset (with the id of the dataset as the file name).
