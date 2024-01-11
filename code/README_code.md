# Table of Contents
- [Table of Contents](#table-of-contents)
  - [Purpose of this directory](#purpose-of-this-directory)
  - [Purpose of each script](#purpose-of-each-script)
    - [Customisation](#customisation)
  - [Understanding the commands](#understanding-the-commands)
  - [Other files](#other-files)
  - [Troubleshooting](#troubleshooting)
    - [*"I can't pull the Docker image"*](#i-cant-pull-the-docker-image)
    - [*"I want to bypass Docker"*](#i-want-to-bypass-docker)
    - [*"The Shiny app doesn't open, even though the script appears to run"*](#the-shiny-app-doesnt-open-even-though-the-script-appears-to-run)
  - [Computational environment](#computational-environment)


## Purpose of this directory

The `code/` directory contains all scripts required to run the pipeline, other than the job script (`jobscript.sh`) - which is kept in the project's root directory for ease-of-access - and the shiny app script (`youngbites.R`) in the `../visualisations/shiny` directory.

It is assumed that no script in this directory will be run individually, instead being run via Docker. However, you may customise how the pipeline is run (see 'Customisation' section).

## Purpose of each script
 
* `jobscript.sh` (in the project root directory): Responsible for running each of the below scripts and for parsing command-line flags (see 'Customisation' section).
* `preprocess.sh`: Joins data from the 'raw' directory, performs initial cleaning steps, and filters observations by age. This preprocessing stage is important to reduce the overall size of the dataset, so that R is able to handle it much more efficiently.
* `data_wrangling.R`: Performs data integrity checks on the merged data (i.e. variable consistency and excluding cases with more than 25% missing data), and creates the derived variables. It also recodes data to make it easily interpretable by subsequent scripts, and is responsible for removing unneeded fields - further improving efficiency. This script produces our final study dataset ('clean_data.csv') in the `clean/` directory. For more information on variables contained within *clean_data.csv*, see `../clean/variable_guide.md`.
* `visualisations.R`: Generates two static visualisations from our cleaned data, and saves them to the `../visualisations/images/` directory. These visualisations depict each of this project's derived variable sets (i.e. 'food consumption indicies', and 'extreme consumption groups').
* `youngbites.R`: Generates the Shiny app ("Young Bites") from the cleaned data and attempts to open it in a browser. Note that this script is located in `../visualisations/shiny/`. This app allows the user to select variables to observe subgroup comparisons for both of these derived variable sets.


### Customisation

This pipeline's scripts may be useful for similar research projects. To facilitate re-use value, several customisation options have been integrated, allowing the scripts to be tailored for different research requirements.

From the project's root directory, run `docker-compose run --rm -e FLAGS="-h" pipeline` to see a list of customisation options for the above scripts. Options include:

* `-v`: skips the static visualisation script (`visualisations.R`)
* `-s`: skips the Shiny app script (`youngbites.R`)
* `-p`: runs `visualisations.R` and `youngbites.R` in parallel (as both of these scripts are only dependent on `data_wrangling.R`). By default, these scripts will be run sequentially.
* `-d`: stop the removal of food consumption fields. By default, `data_wrangling.R` will remove original fields from the `FFQRAW_D.csv` dataset, after producing derived variables, for efficiency purposes. This flag prevents this, giving you access to a fuller version of the study dataset.
* `-g`: saves the static visualisations to SVG format as well as PNG (`visualisations.R`). SVG files are generally recommended for publishing due to their lossless format. Default is to save as PNG only.
* `-i`: attempts to open the Shiny app in the IDE rather than a browser. This is only recommended if you encounter issues with opening the app in the browser as this flag may not work in some IDEs (e.g. VSCode).

The following flags should only be specified *after* the above flags, if required:

* `-a [number]`: sets the minimum age for observation filtering - default is `-a 0` for 0 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard. Note that the youngest observations in the merged dataset are 2 years old, making this the defacto default.
* `-A [number]`: sets the maximum age for observation filtering - default is `-A 12` for 12 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny app.

For example, this line would not produce any static visualisations, but will include observations aged between 6 and 18 in the cleaned dataset and Shiny app:
```
docker-compose run --rm -p 3838:3838 -e FLAGS="-v -a 6 -A 18" pipeline
```

Note that if custom 'age' flags are set, the Shiny app will not allow the user to select the age variable. This is to ensure that inaccurate age groups are not displayed. If you would like to add in your own age groupings, you'll need to manually adjust the `data_wrangling.R` and `youngbites.R` scripts.


## Understanding the commands

The commands to run the pipeline, as outlined above, can be broken down as follows:

* `docker-compose run`: Runs the pipeline in line with the configuration outlined in `../docker-compose.yml`.
* `--rm`: This optional flag removes the Docker container upon exit (avoiding the accumulation of unused containers).
* `-p 3838:3838`: Specifies the local port where the Shiny app will be run. If changed, you must also modify the `../visualisations/youngbites.R` script and the `../docker-compose.yml` file to suit. This can be removed if you plan to skip the Shiny app via the `-s` flag.
* `-e FLAGS=""`: Processes the customisation flags outlined in the above 'Customisation' section. This can be removed if you wish to specify no flags.
* `pipeline`: Specifies the Docker image to run.


## Other files

This pipeline contains a number of auxiliary files that are not directly called upon by the job script, but are otherwise important for it to function properly. These include:
* `code.Rproj`: determines the 'starting point' for relative file paths in R Scripts. A similar file can also be seen in the `../visualisations/shiny` directory.
* `../renv.lock`: Lists the dependencies and version numbers for R and its dependencies. This is used by the Dockerfile.
* `Dockerfile`: Configures the Docker image / computational environment for this pipeline.
* `docker-compose.yml`: Establishes certain configurations required for the pipeline to function as intended. For example, it determines the local port for the Shiny app and ensures that output files are generated in the local directory, rather than Docker's own file system.


## Troubleshooting

This section contains some additional methods for running the pipeline should you encounter issues with the approach outlined in `../README.md`. For clarity, no issues were encountered during testing, though the below situations were deemed to be the most likely issues that could arise.

### *"I can't pull the Docker image"*

This may occur if you are not logged in to Docker. Run `docker login` in the first instance, and check Docker Desktop (if installed) for any other issues.

You may also wish to check the status of the Docker image on [Docker Hub](https://hub.docker.com/repository/docker/sammyosh/child-diet-inequality-image/general).

If you are still encountering issues pulling the Docker image, then you may wish to configure your own image. Make any required changes to the Dockerfile, if needed, and run:

```
docker build -t pipeline .
```

### *"I want to bypass Docker"*

If you're still encountering issues with Docker and/or would prefer to bypass the service altogether, you may instead directly run the job script. 

From the project root directory, simply run `./jobscript.sh` to execute the pipeline. Customisation flags may also be added (e.g. `./jobscript.sh -v -a 6 -A 18`). 

If running the job script directly, you should ensure your local environment is aligned with the Docker image as much as possible, particularly for R and its dependencies. You can do this by closely adhering to the computational environment specification (see below section).


### *"The Shiny app doesn't open, even though the script appears to run"*

While the Shiny app is pending in the terminal, enter `http://localhost:3838/` into your browser. Note that terminating the pipeline will make the Shiny app unavailable locally.

If the Shiny app still refuses to run, then there is likely an issue with the local port not being correctly mapped. Instead, try running the below line. This is a more 'controlled' version of the pipeline, and as such customisation options are not available:

```
docker-compose up pipeline
```


## Computational environment

The pipeline was developed and tested on a Windows 11 PC with WSL 2 (Ubuntu 22.04.3 LTS). It was also tested on a computer running macOS Version 14.2, as well as another Windows 11 PC, running WSL 2 Ubuntu 20.04.03 LTS. Based on testing, no OS-related limitations have been identified.

R scripts were developed using R version 4.1.2 (2021-11-01). This older version of R was used due to compatibility with R Studio Server for WSL, of which there is no later version. 

For a detailed account of this pipeline's computational environment, please see the `Dockerfile` for the system-level environment, and `renv.lock` for the R-specific environment.

[def]: #the-shiny-app-doesnt-open-even-though-the-script-appears-to-run