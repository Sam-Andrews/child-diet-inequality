# Purpose of this directory

The `code/` directory contains all scripts required to run the pipeline, other than the job script (`jobscript.sh`) - which is kept in the project's root directory for ease-of-access - and the shiny app script (`youngbites.R`) in the `../visualisations/` directory.

It is assumed that no script in this directory will be run individually, instead being run via the job script. However, you may customise how the job script is run (see 'Customisation' section).

## Purpose of each script
 
* `preprocess.sh` joins data in the 'raw' directory, performs initial cleaning steps, and filters observations by age. This preprocessing stage is important to reduce the overall size of the dataset, so that R is able to handle it much more efficiently.
* `data_wrangling.R` takes the joined data, performs data integrity checks (i.e. variable consistency and excluding cases with more than 25% missing data), and creates our main study variables. It also recodes data to make it easily interpretable by subsequent scripts, and is responsible for removing unneeded fields. This script produces our final study dataset ('clean_data.csv') in the `clean/` directory. For more information on variables contained within *clean_data.csv*, see `../clean/variable_guide.md`.
* `visualisations.R` generates two static visualisations from our cleaned data, and saves them to the `../visualisations/images/` directory.
* `youngbites.R` generates the Shiny app from the cleaned data and attempts to open it in a browser. Note that this script is located in `../visualisations/shiny/`.


## Customisation

This pipeline's scripts may be useful for similar research projects. To facilitate re-use value, several customisation options have been integrated, allowing the scripts to be tailored for different research requirements.

From the project's root directory, run `./jobscript.sh -h` to see a list of customisation options for the above scripts. Options include:

* `-v`: skips the static visualisation script (`visualisations.R`)
* `-s`: skips the Shiny app script (`youngbites.R`)
* `-d`: stop the removal of food consumption fields. By default, `data_wrangling.R` will remove original fields from the `FFQRAW_D.csv` dataset for efficiency purposes. This flag prevents this, giving you access to a fuller version of the study dataset.
* `-p`: runs `visualisations.R` and `youngbites.R` in parallel (as both of these scripts are only dependent on `data_wrangling.R`). By default, these scripts will be run sequentially.
* `-g`: saves the static visualisations to SVG format as well as PNG. SVG files are generally recommended for publishing due to its lossless format (`visualisations.R`). Default is to save PNG only.
* `-i`: opens the Shiny app in a GUI rather than a browser. This is only recommended if you encounter issues with opening the app in the browser as this flag may not work in some GUIs (e.g. VSCode)

The following flags should only be specified *after* the above flags, if required:

* `-a [number]`: sets the minimum age for observation filtering - default is `-a 0` for 0 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard.
* `-A [number]`: sets the maximum age for observation filtering - default is `-A 12` for 12 years old (`preprocess.sh`). This flag will impact *clean_data.csv*, both static visualisations, and the Shiny dashboard.

For example, this line would not produce any static visualisations, but will include observations aged between 6 and 18 in our cleaned dataset and Shiny app:
```
./jobscript.sh -v -a 6 -A 18
```

Note that if custom 'age' flags are set, the Shiny app will not allow the user to select the age variable. This is to ensure that inaccurate age groups are not displayed. If you would like to add in your own age groupings, you'll need to manually adjust the `data_wrangling.R` and `youngbites.R` scripts.

## Other files

This directory contains a number of other files that are not directly called by the job script, but are otherwise necessary for the other scripts to run. These include:
* `renv.lock`: manages and automatically installs dependencies for R Scripts via `renv`. This serves as a record of this pipeline's computational environment.
* `.Rprofile`: ensures `renv` is activated.
* `code.Rproj`: determines the 'starting point' for relative file management in R Scripts.

Similar files are also seen in the `../visualisations/shiny/` directory for the `youngbites.R` script, and serve similar purposes.

## Other considerations

Please note that R scripts were written using R version 4.1.2 (2021-11-01). This older version of R was used due to compatibility with R Studio Server for WSL, of which there is no later version. If you have a later version of R on your machine, `renv` may reinstall R version 4.1.2.

The first time these scripts run, your machine may also need to install package dependencies. Therefore, the pipeline may take substantially more time to run in the first instance.