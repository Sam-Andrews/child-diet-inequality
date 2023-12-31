# Young Bites, Big Questions: Unpacking Diet and Disparity among US Children

## Overview
This project uses NHANES data to explore dietary consumption in early and middle childhood (aged 12 and under).

Its features include:
* Creation of two derived variable sets: _"index scores"_ and _"unhealthy consumption signifiers"_ for fruit, vegetable and sugar.
* A static data visualisation for each variable set.
* A `shiny` app, allowing users to filter data, identifying vulnerable groups.

For an overview of the pipeline's scripts and customisation options, see `code/README_code.md`.


## Getting started

If using Windows, please ensure you have [WSL 2 enabled](https://learn.microsoft.com/en-us/windows/wsl/install). 

Make sure your Shell is set to `bash`:
```
chsh -s /bin/bash
```

Additionally, you need to have `R` installed. For Ubuntu/Debian-based systems, you can install `R` by running:
```
sudo apt update
sudo apt install r-base
```
Since this pipeline uses `renv` for automatic dependency management, you do not need to manually install specific packages to execute scripts. 

Before running the pipeline, it should be made executable. In the project root directory, run:
```
chmod +x jobscript.sh
```
From here, you may execute the pipeline:
```
./jobscript.sh
```
Or, to see customisation options:
```
./jobscript.sh -h
```

### Assumed directory structure

*Output files are denoted with `*`*:

```
ProjectRoot/
├── README.md
├── job_script.R
├── report.pdf
│
├── code/
│   ├── README_code.md
│   ├── preprocess.sh
│   ├── data_wrangling.R
│   ├── visualisations.R
│   ├── .Rprofile
│   ├── code.Rproj
│   ├── renv.lock
│   └── renv/
│
├── raw/
│   ├── DEMO_D.csv
│   ├── FFQRAW_D.csv
│   └── BMI.csv
│
├── clean/
│   ├── clean_data.csv*
│   └── variable_guide.md
│
├── visualisations/
│   ├── images/
│   │   ├── extreme_consumption.png*
│   │   └── index_vis.png*
│   ├── shiny/
│   │   ├── young.bites.R
│   │   ├── renv.lock
│   │   ├── renv/
│   │   └── shiny.Rproj
│   └── 
└── 