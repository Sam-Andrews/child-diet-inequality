# Purpose of this directory

The `code/` directory contains all scripts required to run the pipeline, other than the job script (`jobscript.sh`) - which is kept in the project's root directory for ease-of-access - and the shiny app script (`youngbites.R`) in the `../visualisations/shiny` directory.

It is assumed that no script in this directory will be run individually, instead being run via Docker. However, you may customise how the job script is run (see 'Customisation' section).

## Purpose of each script
 
* `jobscript.sh` (in the project root directory): Responsible for running each of the below scripts and for parsing command-line flags (see 'Customisation' section)
* `preprocess.sh`: Joins data from the 'raw' directory, performs initial cleaning steps, and filters observations by age. This preprocessing stage is important to reduce the overall size of the dataset, so that R is able to handle it much more efficiently.
* `data_wrangling.R`: Performs data integrity checks on the merged data (i.e. variable consistency and excluding cases with more than 25% missing data), and creates our main study variables. It also recodes data to make it easily interpretable by subsequent scripts, and is responsible for removing unneeded fields - further improving efficiency. This script produces our final study dataset ('clean_data.csv') in the `clean/` directory. For more information on variables contained within *clean_data.csv*, see `../clean/variable_guide.md`.
* `visualisations.R`: Generates two static visualisations from our cleaned data, and saves them to the `../visualisations/images/` directory. These visualisations depict each of this project's derived variable sets (i.e. 'food consumption indicies', and 'extreme consumption groups').
* `youngbites.R`: Generates the Shiny app ("Young Bites") from the cleaned data and attempts to open it in a browser. Note that this script is located in `../visualisations/shiny/`. This app allows the user to select variables to observe subgroup comparisons for both of these derived variable sets.


## Customisation

This pipeline's scripts may be useful for similar research projects. To facilitate re-use value, several customisation options have been integrated, allowing the scripts to be tailored for different research requirements.

From the project's root directory, run `docker-compose run --rm -e FLAGS="-h" pipeline` to see a list of customisation options for the above scripts. Options include:

* `-v`: skips the static visualisation script (`visualisations.R`)
* `-s`: skips the Shiny app script (`youngbites.R`)
* `-p`: runs `visualisations.R` and `youngbites.R` in parallel (as both of these scripts are only dependent on `data_wrangling.R`). By default, these scripts will be run sequentially.
* `-d`: stop the removal of food consumption fields. By default, `data_wrangling.R` will remove original fields from the `FFQRAW_D.csv` dataset, after producing derived variables, for efficiency purposes. This flag prevents this, giving you access to a fuller version of the study dataset.
* `-g`: saves the static visualisations to SVG format as well as PNG (`visualisations.R`). SVG files are generally recommended for publishing due to its lossless format. Default is to save as PNG only.
* `-i`: opens the Shiny app in the IDE rather than a browser. This is only recommended if you encounter issues with opening the app in the browser as this flag may not work in some IDEs (e.g. VSCode).

The following flags should only be specified *after* the above flags, if required:

* `-a [number]`: sets the minimum age for observation filtering - default is `-a 0` for 0 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard. Note that the youngest observations in the merged dataset are 2 years old, making this the defacto default.
* `-A [number]`: sets the maximum age for observation filtering - default is `-A 12` for 12 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard.

For example, this line would not produce any static visualisations, but will include observations aged between 6 and 18 in the cleaned dataset and Shiny app:
```
docker-compose run --rm -p 3838:3838 -e FLAGS="-v -a 6 -A 18" pipeline
```

Note that if custom 'age' flags are set, the Shiny app will not allow the user to select the age variable. This is to ensure that inaccurate age groups are not displayed. If you would like to add in your own age groupings, you'll need to manually adjust the `data_wrangling.R` and `youngbites.R` scripts.


### Understanding the commands

The commands to run the pipeline, as outlined above, can be broken down as follows:

* `docker-compose run`: Runs the pipeline in line with the configuration outlined in `../docker-compose.yml`.
* `--rm`: This optional flag removes the Docker container upon exit (avoiding the accumulation of unused containers).
* `-p 3838:3838`: This specifies the local port where the Shiny app will be run. If changed, you must also modify the `../visualisations/youngbites.R` script and the `../docker-compose.yml` file to suit. This can be removed if you plan to skip the Shiny app via the `-s` flag.
* `-e FLAGS=""`: Processes the customisation flags outlined in the 'Customisation' section. This can be removed if you wish to specify no flags.
* `pipeline`: Specifies the Docker image to run.


## Other files

This pipeline contains a number of auxiliary files that are not directly called by the job script, but are otherwise important for reproducibility. These include:
* `code.Rproj`: determines the 'starting point' for relative file path management in R Scripts. A similar file can also be seen in the `../visualisations/shiny` directory.
* `../renv.lock`: Lists the dependencies and version numbers for specific R dependencies. This is used by the Dockerfile to configure the pipeline's environment.
* `Dockerfile`: Used to configure the Docker image for this pipeline, ensuring reproducbility.
* `docker-compose.yml`: Establishes certain configurations required for the pipeline to function as intended. For example, it determines the local port for the Shiny app and ensures that output files are generated in the local directory, rather than Docker's own file system.


Similar files are also seen in the `../visualisations/shiny/` directory for the `youngbites.R` script, which serve the same purpose.


## Troubleshooting

As outlined in `../README.md`, this line should also run the pipeline (though customisation flags will not be available):

```
docker-compose up pipeline
```

If the pipeline still does not run, it is likely that there is an issue with the Docker image. You may wish to configure your own Docker image by running this line. Be sure to replace `your_image_name` with the name of your desired Docker image, such as `pipeline`:

```
docker build -t your_image_name .
```

Finally, you may wish to bypass Docker altogether. From the project root directory, simply run `./jobscript.sh` to execute the pipeline. Customisation flags may be added (e.g. `./jobscript.sh -v -a 6 -A 18`). You should ensure your local environment is aligned with the below section as much as possible, particularly for R and its dependencies.


## Computational environment

The pipeline was developed and tested on a Windows 11 PC with WSL 2 (Ubuntu 22.04.3 LTS). It was also tested on a computer running macOS Version 14.

R scripts were developed using R version 4.1.2 (2021-11-01). This older version of R was used due to compatibility with R Studio Server for WSL, of which there is no later version. 

For a detailed account of this pipeline's computational environment, please see the `Dockerfile` for the system-level environment, and `renv.lock` for the R-specific environment.