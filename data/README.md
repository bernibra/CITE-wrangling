# Instructions for adding data to the repository

## Using [`CITE-formatting`](https://github.com/bernibra/CITE-formatting) (recommended)

We created a [little app](https://github.com/bernibra/CITE-formatting) to help you add new datasets to the CITE-wranling pipeline. Clone the repository and follow the instructions to set up the app.

![](img/CITE-formatting.png | width=200)

Fill in the form as accurately as possible. Answering the questions regarding how to read the data might require you to manually download some of the files. Unfortunately, there is no way around it. The CITE-wrangling will do its best to read the data as is; however, the more information, the more likely it is for it to run smoothly.

Once the form is completed, download the file and add it to `./data/databases`. The file name will be the id of the new dataset with the corresponding yaml extension. If another dataset has the same id, you must change it for the new dataset, as the pipeline relies on those being unique.

If other information, regarding the samples for example, needs to be added, one can store it as a csv to `./data/xtra_metadata`. The file name must be the id of the new dataset with the corresponding csv extension.

## Manual crafting of the `yaml`

One can also use [this documentation](README_manual.md) to write the configuration file for the new datasets. This is a little convoluted and can lead to very frustrating errors; hence the creation of `CITE-formatting`.


