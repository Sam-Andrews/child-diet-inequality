# Purpose of this directory

The `code/` directory contains all scripts required to run the pipeline, other than the job script (`jobscript.sh`) which is kept in the project's root directory for ease-of-access.

It is assumed that no script in this directory will be run individually, instead being run via the job script. However, you may customise how the job script is run (see 'Customisation' section).

## Purpose of each script 
* `preprocess.sh` joins data in the 'raw' directory, performs initial cleaning steps, and filters observations by age.
* `data_wrangling.R` takes the joined data and creates our main study variables. It also recodes data to make it easily interpretable by subsequent scripts. This script produces our final study dataset ('cleaned_data.csv') in the 'clean' directory.
* `visualisations.R` generates two static visualisations from our cleaned data, and saves them to the 'visualisations' directory.
* `app.R` generates the Shiny app from the cleaned data and attempts to open it in a browser.

## Customisation

From the project's root directory, you can run `./jobscript.sh -h` to see a list of customisation options for scripts contained within this directory. Options include:
* `-v`: skips the static visualisation script (`visualisations.R`)
* `-s`: skips the Shiny app script (`app.R`)
* `-a [number]`: sets the minimum age for observation filtering - default is `-a 0` for 0 years old (`preprocess.sh`). This will impact _clean_data.csv_, both static visualisations, and the Shiny dashboard.
* `-A [number]`: sets the maximum age for observation filtering - defailt is `-A 12` for 12 years old (`preprocess.sh`). This will impact _clean_data.csv_, both static visualisations, and the Shiny dashboard.
* `-p`: runs `visualisations.R` and `app.R` in parallel (as both of these scripts are only dependent on `data_wrangling.R`)
* `-g`: saves the static visualisations to SVG format instead of PNG. SVG files are generally recommended for publishing due to its lossless format (`visualisations.R`)
* `-i`: opens the Shiny app in a GUI rather than a browser. This is only recommended if you encounter issues with opening the app in the browser.

For example, this line would not produce any static visualisations, but will include observations ages between 6 and 18 in our cleaned dataset and Shiny dashboard:
```
./jobscript.sh -v -a 6 -A 18
```

## Other files

This directory contains a number of other files that are not directly called by the job script, but are otherwise necessary for the other scripts to run. These include:
* `renv.lock`: manages and automatically installs dependencies for R Scripts via `renv`.
* `.Rprofile`: ensures `renv` is activated.
* `code.Rproj`: determines the 'starting point' for relative file management in R Scripts.




