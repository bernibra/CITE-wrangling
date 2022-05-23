# From:
# https://github.com/jkanche/random-test-files/blob/master/_scripts/compact10x.R

# Contains a function to compactly create a 10X matrix. 
# This should be a faster way to write an HDF5 object than saveHDF5SummarizedExperiment

library(rhdf5)
compact10x <- function(path, x, ids, symbols) {
    h5createFile(path)
    h5createGroup(path, "matrix")
    h5write(dim(x), path, "matrix/shape")

    y <- as(x, "dgCMatrix")
    stopifnot(all(y@x == round(y@x))) # must be integer.
    limits <- range(y@x)
    stopifnot(limits[1] >= 0)

    if (limits[2] < 2^16) {
        xstore <- "H5T_NATIVE_USHORT"
    } else {
        xstore <- "H5T_NATIVE_UINT"
    }
    h5createDataset(path, "matrix/data", dims=length(y@x), H5type=xstore, chunk=200000);
    h5write(y@x, path, "matrix/data")

    if (nrow(x) < 2^16) {
        istore <- "H5T_NATIVE_USHORT"
    } else {
        istore <- "H5T_NATIVE_UINT"
    }
    h5createDataset(path, "matrix/indices", dims=length(y@i), H5type=istore, chunk=200000);
    h5write(y@i, path, "matrix/indices")

    h5createDataset(path, "matrix/indptr", dims=length(y@p), H5type="H5T_NATIVE_ULONG", chunk=1000);
    h5write(y@p, path, "matrix/indptr")

    h5createGroup(path, "matrix/features")
    h5write(ids, path, "matrix/features/id")
    h5write(symbols, path, "matrix/features/name")
}
