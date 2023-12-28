#!/usr/bin/env bash

### This script can be used to automatically run the project's data processing pipeline ###
### It is intended to be run from the project's root directory ###

# Inisiailise variables

skip_visualisations=false
skip_shiny_app=false

# Function to display help

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h    Display help"    
    echo "  -v    Skip static visualisations script"
    echo "  -s    Skip Shiny app script"
}

# Parse command line options

while getopts "hvs" opt; do
    case "$opt" in
    h) 
        show_help
        exit 0
        ;;
    v) skip_visualisations=true ;; # ...flag to skip static visualisations script
    s) skip_shiny_app=true ;; # ...flag to skip Shiny app script
    *) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
done

# Set directory to where scripts are stored

cd code || { echo "Failed to change directory to 'code'. Make sure your directories follow the same structure outlined in README.md."; exit 1; }


# Run data processing script

echo "RUNNING DATA PROCESSING SCRIPT..."
bash preprocess.sh


# Run data wrangling script

echo "RUNNING DATA WRANGLING SCRIPT..."
Rscript data_wrangling.R


# Run data visualisation script if flag not set

if ! $skip_visualisations; then
    echo "RUNNING DATA VISUALISATION SCRIPT..."
    Rscript visualisations.R
fi


# Run "youngbites" Shiny app script if flag not set

if ! $skip_shiny_app; then
    echo "RUNNING SHINY APP SCRIPT..."
    Rscript app.R
fi

# Delete old data

#rm ../clean/data.rds
#rm ../raw/merged.csv


# All scripts run

echo "All scripts run!"

echo "Please check the 'clean' directory for the cleaned and merged dataset."

if ! $skip_visualisations; then
    echo "Please check the 'visualisations' directory for the visualisations."
fi