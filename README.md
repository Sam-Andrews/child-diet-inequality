# Young Bites, Big Questions: Unpacking Diet and Disparity among US Children

## Overview
This project uses NHANES data to analyse dietary consumption in early and middle childhood (ages 12 and under).

It has a number of key features, including:
* Creation of two sets of derived variables: _"index scores"_ and _"unhealthy consumption signifiers"_ for fruit, vegetable and sugary item consumption.
* Two static data visualisations for each of these variable sets.
* An interactive Shiny dashboard, allowing the user to filter the data to identify vulnerable groups.

For a detailed overview of this pipeline's scripts, stages and customisation options, see [`code/README_code.md`](https://github.com/Sam-Andrews/child-diet-inequality/blob/main/code/README_code.md).


## Getting started
**Prerequisites:**

If using Windows, please ensure you have [WSL 2 enabled](https://learn.microsoft.com/en-us/windows/wsl/install). 

Ensure your Shell is set to `bash`:
```
chsh -s /bin/bash
```

Additionally, you need to have `R` installed. For Ubuntu/Debian-based systems, you can install `R` by running:
```
sudo apt update
sudo apt install r-base
```
Since this pipeline uses `renv` for automatic dependency management, you do not need to install specific packages to execute scripts in this pipeline. 

Before running the pipeline, it should first be made executable. In the project root directory, run:
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

### Directory structure

Scripts require the following structure (output files are denoted with `*`) :

```
ProjectRoot/
│
├── README.md
├── job_script.R
├── report.pdf
│
├── code/
│ ├── preprocess.sh
│ ├── data_wrangling.R
│ ├── visualisations.R
│ ├── app.R
│ ├── .Rprofile
│ ├── code.Rproj
│ └── renv.lock
│ └── renv/
│
├── raw/
│ ├── DEMO_D.csv
│ ├── FFQRAW_D.csv
│ ├── BMI.csv
│
├── clean/
│ ├── clean_data.csv*
│ ├── variable_guide.md
│
├── visualisations/
│ ├── extreme_consumption.png*
│ ├── index_vis.png*
└── 
