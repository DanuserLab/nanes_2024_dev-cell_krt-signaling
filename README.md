# Manuscript code repository - Nanes et al., 2024

This repository contains code used in [**Shifts in keratin isoform expression activate motility signals during wound healing**](https://doi.org/10.1016/j.devcel.2024.06.011), *Developmental Cell*, 2024, 59(20), 2759 - 2771.e11, by Benjamin A Nanes, Kushal Bhatt, Evgenia Azarova, Divya Rajendran, Sabahat Munawar, Tadamoto Isogai, Kevin M Dean, and Gaudenz Danuser. Additional information can be found in the methods section of the paper.

Rather than using this repository directly, most users will find it more convenient to download stand-alone software packages with documentation, graphical user interfaces, and additional features from the [Danuser Lab software page](https://github.com/DanuserLab/). However, this repository contains example scripts and small modifications to facilitate batch processing on HPC systems that developers may find useful. It also serves as a reference version of the code used in the paper. Note that while the underlying packages are actively maintained and may be updated, code in this repository is provided as-is. This code was run using Matlab version 2020b.

## Contents

### Data Setup

Scripts in this repository use the `MovieData` class to organize image data, metadata, and analysis results. A `MovieData` object needs to be created for each image prior to running these pipelines. This can be done using the package GUIs or by modifying the `makeMDs.m` script from this repository.

### Migration Analysis

Scripts in the `migration` folder use the [MonolayerKymographs](https://github.com/DanuserLab/MonolayerKymographs) package (Zaritsky et al., J Cell Biol, 2017) to analyze live imaging of monolayer or epidermal organoid migration assays. Note that this repository contains an adapted version of the package providing additional flexibility required for the epidermal organoid images.

- `procTimelapse_monolayer_tif.m` runs the original package for monolayer images.
- `procTimelapse_monolayer_MD.m` runs the adapted package for monolayer images.
- `procTimelapse_EECs.m` runs the adapted package for epidermal organoids.
- `segmentFluors.m` runs Otsu segmentation to annotate expression regions.
- `tabulateData_byRegion.m` extracts migration data split by expression region.
- `tabulateData_totalArea.m` extracts global migration area data.

### Filament Segmentation and Analysis

Scripts in the `filaments` folder use a modified version of the [u-delineate](https://github.com/DanuserLab/u-delineate) package (Gan et al., Cell Systems, 2016) to segment and analyze live imaging of intermediate filament networks. Note that this repository lacks features available in the latest u-delineate package release.

- `runFilSegDyn.m` runs the package to segment filament networks and create dynamics score maps.
- `runScrambledControl.m` creates synthetic "scrambled" filament networks to serve as controls for similarity measurements.
- `wrangleData.m` extracts tabular data after running the package.
- `wrangleData_curvature.m` extracts additional tabular data related to filament network snapshots.

### Traction Force Microscopy

Scripts in the `TFM` folder use the [u-inferforce](https://github.com/DanuserLab/u-inferforce) package (Han et al., Nature Methods, 2015) to reconstruct traction forces from traction force microscopy (TFM) images. This routine can be used to automate processing of a large number of images. An HPC cluster with >= 64 GB memory per node is recommended for the fastBEM method.

- `getFileLists.m` is a convenience function to specify dataset organization. This function must be modified for each project.
- `runTFMcalc.m` invokes the u-inferforce package.
- `tabulateData.m` extracts per-cell data such as strain energy density.

### Proximity Ligation Assay

Scripts in the `PLA` folder are used to analyze Proximity Ligation Assay experiments. 

- `plaDetect.m` uses wavelet denoising and multiscale products of wavelet coefficients to detect PLA signals. This algorithm was previously published as part of Aguet et al., Dev Cell, 2013 and is based on Olivo-Marin 2022.
- Three python notebooks, `run-cellpose.ipynb`, `wrangle-data.ipynb`, and `visualizations.ipynb` can be used for downstream analysis. Cell segmentation is performed using [Cellpose](https://www.cellpose.org/), which must be installed separately. 

### Package Libraries

All code required for the dependent packages is bundled in the `library` folder, which should be added to the Matlab path.

## Links
[Software Links](https://github.com/DanuserLab/)

[Danuser Lab Website](https://www.danuserlab-utsw.org/)

[Nanes Lab Website](https://lab.nanes.org)
