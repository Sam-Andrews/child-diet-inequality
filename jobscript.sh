#!/usr/bin/env bash

### This script can be used to automatically run the project's data processing pipeline ###
### It is intended to be run from the project's root directory ###

# Run data processing script

echo "RUNNING DATA PROCESSING SCRIPT..."

cd code 

bash preprocess.sh

# Run data wrangling script

echo "RUNNING DATA WRANGLING SCRIPT..."

Rscript data_wrangling.R

# Run data visualisation script

echo "RUNNING DATA VISUALISATION SCRIPT..."

Rscript visualisations.R

# Run "youngbites" Shiny app script

#Rscript youngbites/app.R

# Delete old data

rm ../clean/data.rds
rm ../raw/merged.csv


# All scripts run

echo "All scripts run!"
echo "Please check the 'clean' directory for the cleaned and merged dataset."
echo "Please check the 'visualisations' directory for the visualisations."