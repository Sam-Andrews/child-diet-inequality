#!/usr/bin/env bash

### This script can be used to automatically run the project's data processing pipeline ###
### It is intended to be run from the project's root directory ###

# Initialise variables

skip_visualisations=false
skip_shiny_app=false
run_in_parallel=false

# Function to display help via `./jobscript.sh -h`

show_help() {
    echo "Usage: $0 [-h -v -s -a -A -p]"
    echo "Options:"
    echo "  -h    Display help"    
    echo "  -v    Skip static visualisations script"
    echo "  -s    Skip Shiny app script"
    echo "  -a    Set minimum age to filter by (default is -a 0 for 0 years old). Ensure there's a space between '-a' and your chosen age."  # ...this is read by preprocess.sh
    echo "  -A    Set maximum age to filter by (default is -A 12 for 12 years old). Ensure there's a space between '-A' and your chosen age."  # ...this is read by preprocess.sh
    echo "  -p    Run visualisations.R and Shiny app.R scripts in parallel (default is to run sequentially)"
}

# Parse command line options

while getopts "hvsp" opt; do
    case "$opt" in
    h) 
        show_help
        exit 0
        ;;
    v) skip_visualisations=true ;; # ...flag to skip static visualisations script
    s) skip_shiny_app=true ;; # ...flag to skip Shiny app script
    p) run_in_parallel=true ;; # ...flag to run scripts in parallel
    a) ;; # ...recognise flag but do nothing (since it's for preprocess.sh)
    A) ;; # ...recognise flag but do nothing (since it's for preprocess.sh)
    *) # ...ignore other flags
        ;;
    esac
done

# Check for conflicting flags
if $run_in_parallel; then
    if $skip_visualisations || $skip_shiny_app; then
        echo "Error: The -p flag cannot be used with -s or -v."
        exit 1
    fi
fi

# Set directory to where scripts are stored

cd code || { echo "Failed to change directory to 'code'. Make sure your directory strucutre is exactly as outlined in README.md."; exit 1; }


# Run data processing script

echo "RUNNING DATA PROCESSING SCRIPT..."
# ...pass command line arguments to preprocess.sh
bash preprocess.sh "$@" || { echo "Failed to run data processing script."; exit 1; }


# Run data wrangling script

echo "RUNNING DATA WRANGLING SCRIPT..."
Rscript data_wrangling.R || { echo "Failed to run data wrangling script."; exit 1; }


# Function to run data visualisation script
run_visualisations() {
    echo "RUNNING DATA VISUALISATION SCRIPT..."
    Rscript visualisations.R || { echo "Failed to run data visualisation script."; exit 1; }
}

# Function to run Shiny app script
run_shiny_app() {
    echo "RUNNING SHINY APP SCRIPT..."
    Rscript app.R || { echo "Failed to run Shiny app script."; exit 1; }
}


# Run scripts based on flags
if $run_in_parallel; then
    if ! $skip_visualisations; then
        run_visualisations &
    fi
    if ! $skip_shiny_app; then
        run_shiny_app &
    fi
    wait # Wait for all background processes to finish
else
    if ! $skip_visualisations; then
        run_visualisations
    fi
    if ! $skip_shiny_app; then
        run_shiny_app
    fi
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