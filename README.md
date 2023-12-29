# Young Bites, Big Questions: Unpacking Diet and Disparity among US Children

## Introduction
This pipeline uses NHANES data to analyse dietary consumption in early and middle childhood (ages 12 and under). It examines the prevelence and correlates of unhealthy consumption frequency.

It has a number of key features, including:
* Creation of two derived variables: _"index scores"_ and _"unhealthy consumption signifiers"_ for fruit, vegetable and sugary item consumption.
* Two static data visualisations, outlining the distributions of each index variable and the prevelence of unhealthy consumption signifiers.
* An interactive Shiny dashboard, allowing the user to filter the data to identify vulnerable groups.


## Compendium Overview
For a detailed overview of each script, please see the separate README in the 'code' directory.

At a high-level, this pipeline uses Bash scripting to pre-process data, including joining datasets, filtering by age and providing initial cleaning steps. R scripting is used to generate index and unhealthy consumption variables, and produces the final study dataset. Additional R Scripts create the static visualisations using `ggplot2` and the interactive dashboard using `shiny`.


## Getting started
**Prerequisites:**

If using Windows, please ensure you have [WSL 2 enabled](https://learn.microsoft.com/en-us/windows/wsl/install). The command-line Shell must be set to _Bash_, regardless of OS. 

Additionally, you need to have R installed. For Ubuntu/Debian-based systems, you can install R by running:
```
sudo apt update
sudo apt install r-base
```
Since this pipeline uses `renv` for automatic dependency management, you do not need to install specific packages to execute scripts in this pipeline. 

Before running the pipeline, it should first be made executable. Navigate to the project's root directory and run:
```
chmod +x job_script.sh
```
From here, you may simply run:
```
./job_script.sh
```
Alternatively, this pipeline has customisation options. These can be accessed through running:
```
./job_script.sh -h
```
