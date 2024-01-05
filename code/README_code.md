# Purpose of this directory

The `code/` directory contains all scripts required to run the pipeline, other than the job script (`jobscript.sh`) - which is kept in the project's root directory for ease-of-access - and the shiny app script (`youngbites.R`) in the `../visualisations/` directory.

It is assumed that no script in this directory will be run individually, instead being run via the job script. However, you may customise how the job script is run (see 'Customisation' section).

## Purpose of each script
 
* `preprocess.sh` joins data in the 'raw' directory, performs initial cleaning steps, and filters observations by age. This preprocessing stage is important to reduce the overall size of the dataset, so that R is able to handle it much more efficiently.
* `data_wrangling.R` takes the joined data, performs data integrity checks (i.e. variable consistency and excluding cases with more than 25% missing data), and creates our main study variables. It also recodes data to make it easily interpretable by subsequent scripts, and is responsible for removing unneeded fields, further improving efficiency. This script produces our final study dataset ('clean_data.csv') in the `clean/` directory. For more information on variables contained within *clean_data.csv*, see `../clean/variable_guide.md`.
* `visualisations.R` generates two static visualisations from our cleaned data, and saves them to the `../visualisations/images/` directory. These visualisations describe each of this project's derived variable sets (i.e. food consumption indicies, and 'extreme consumption' groups).
* `youngbites.R` generates the Shiny app ("Young Bites") from the cleaned data and attempts to open it in a browser. Note that this script is located in `../visualisations/shiny/`. This app allows the user to select variables to observe subgroup comparisons for both of these derived variable sets.


## Customisation

This pipeline's scripts may be useful for similar research projects. To facilitate re-use value, several customisation options have been integrated, allowing the scripts to be tailored for different research requirements.

From the project's root directory, run `./jobscript.sh -h` to see a list of customisation options for the above scripts. Options include:

* `-v`: skips the static visualisation script (`visualisations.R`)
* `-s`: skips the Shiny app script (`youngbites.R`)
* `-p`: runs `visualisations.R` and `youngbites.R` in parallel (as both of these scripts are only dependent on `data_wrangling.R`). By default, these scripts will be run sequentially.
* `-d`: stop the removal of food consumption fields. By default, `data_wrangling.R` will remove original fields from the `FFQRAW_D.csv` dataset, after producing derived variables, for efficiency purposes. This flag prevents this, giving you access to a fuller version of the study dataset.
* `-g`: saves the static visualisations to SVG format as well as PNG. SVG files are generally recommended for publishing due to its lossless format (`visualisations.R`). Default is to save PNG only.
* `-i`: opens the Shiny app in the IDE rather than a browser. This is only recommended if you encounter issues with opening the app in the browser as this flag may not work in some IDEs (e.g. VSCode)

The following flags should only be specified *after* the above flags, if required:

* `-a [number]`: sets the minimum age for observation filtering - default is `-a 0` for 0 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard.
* `-A [number]`: sets the maximum age for observation filtering - default is `-A 12` for 12 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard.

For example, this line would not produce any static visualisations, but will include observations aged between 6 and 18 in the cleaned dataset and Shiny app:
```
./jobscript.sh -v -a 6 -A 18
```

Note that if custom 'age' flags are set, the Shiny app will not allow the user to select the age variable. This is to ensure that inaccurate age groups are not displayed. If you would like to add in your own age groupings, you'll need to manually adjust the `data_wrangling.R` and `youngbites.R` scripts.

## Other files

This directory contains a number of auxiliary files that are not directly called by the job script, but are otherwise necessary for the other scripts to run. These include:
* `renv.lock`: manages and automatically installs dependencies for R Scripts via `renv`.
* `.Rprofile`: ensures `renv` is activated.
* `code.Rproj`: determines the 'starting point' for relative file management in R Scripts

Similar files are also seen in the `../visualisations/shiny/` directory for the `youngbites.R` script, which serve the same purpose.

## Computational environment

The pipeline was developed and tested on a Windows 11 PC with WSL 2 (Ubuntu 22.04.3 LTS).

R scripts were developed using R version 4.1.2 (2021-11-01). This older version of R was used due to compatibility with R Studio Server for WSL, of which there is no later version. If you have a later version of R on your machine, `renv` may reinstall R version 4.1.2. However, no compatibility issues have been identified between different versions of R.

A detailed account of R dependencies can be found in the `renv.lock` files in both the `code/` and `visualisations/shiny/` directories. Running the pipeline via `jobscript.sh` should automatically install these packages (and so may take substantially longer to run in the first instance).