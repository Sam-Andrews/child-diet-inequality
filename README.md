# Young Bites, Big Questions: Unpacking Diet and Disparity among US Children

## Overview
This project uses NHANES data to explore dietary consumption in early and middle childhood (aged 12 and under).

Its features include:
* Creation of two derived variable sets: _index scores_ and _unhealthy consumption signifiers_ for fruit, vegetable and sugar.
* A static data visualisation for each variable set.
* A `shiny` app, allowing users to select and compare variables, identifying vulnerable groups.

For an overview of the pipeline's scripts and customisation options, see `code/README_code.md`.

## Getting started

### Prerequisites

Please ensure [Docker](https://docs.docker.com/engine/install/) is installed on your system.

If using Windows, please [enable WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install). 

As this pipeline uses Docker for environment management, you do not need to install R or any specific dependencies.

### Running the pipeline

You'll first need to pull the pipeline's Docker image. In the Bash command-line, run:

```
docker pull sammyosh/child-diet-inequality-image:latest
```

Then, to build and execute the pipeline, run:

```
docker-compose run --rm -p 3838:3838 pipeline
```

Or, for customisation options:

```
docker-compose run --rm -e FLAGS="-h" pipeline
```

For more information on this pipeline's customisation options, please see `code/README_code.md`

### Alterative approach

After building the Docker image, the pipeline can be run (without customisation flags) through:

```
docker-compose up pipeline
```

### Compendium structure

Output files are denoted with `*`:

```
ProjectRoot/
├── README.md
├── jobscript.R
├── report.pdf
├── Dockerfile
├── docker-compose.yml
├── renv.lock
│
├── clean/
│   ├── clean_data.csv*
│   └── variable_guide.md
│
├── code/
│   ├── README_code.md
│   ├── preprocess.sh
│   ├── data_wrangling.R
│   ├── visualisations.R
│   └── code.Rproj
│
├── raw/
│   ├── DEMO_D.csv
│   └── FFQRAW_D.csv
│
├── visualisations/
│   ├── images/
│   │   ├── extreme_consumption.png*
│   │   └── index_vis.png*
│   ├── shiny/
│   │   ├── youngbites.R
│   │   └── shiny.Rproj
│   └── 
└── 