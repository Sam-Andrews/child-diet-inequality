#!/usr/bin/env bash

# This script can be used to automatically run the project's data processing pipeline and 
# process customisation options. It is intended to be run from the project's root directory.

# Initialise flag variables

skip_visualisations=false
skip_shiny_app=false
run_in_parallel=false
save_svg=false
shiny_gui=false
keep_fields=false

# Function to display help via `./jobscript.sh -h`

show_help() {
    echo "Usage: $0 [-h -v -s -p -d -g -i -a -A]"
    echo ""
    echo "For more information about these flags, please see 'code/README_code.md'."
    echo ""
    echo "Options:"
    echo "  -h    Display help"    
    echo "  -v    Skip static visualisations script (visualisations.R)"
    echo "  -s    Skip Shiny app script (youngbites.R)"
    echo "  -p    Run visualisations.R and Shiny app.R scripts in parallel (default is to run sequentially)"
    echo "  -d    Keep food consumption fields in clean_data.csv
        Default is to remove unneeded fields from FFQRAW_D.csv for computational efficiency" # ...this is read by data_wrangling.R
    echo "  -g    Save static visualisations in both PNG & SVG formats (default is PNG only)" # ...this is read by visualisations.R
    echo "  -i    Open Shiny app in IDE (default is to open in browser)
        Note that some IDEs (e.g. VSCode) may ignore this flag" # ...this is read by youngbites.R
    echo ""
    echo "Please specify the following flags *after* the above options, if applicable:"
    echo "  -a    Set minimum age (default is -a 0 for 0 years old)
        Ensure there's a space between '-a' and your chosen age"  # ...this is read by preprocess.sh
    echo "  -A    Set maximum age (default is -A 12 for 12 years old)
        Ensure there's a space between '-A' and your chosen age"  # ...this is read by preprocess.sh
}


# Parse command line options

# ...first, read in flags via docker-compose.yml file
if [ -n "$FLAGS" ]; then
  set -- $FLAGS
fi

# ...then, process flags via getopts loop

while getopts "hvspaAgid" opt; do
    case "$opt" in
    h) 
        show_help
        exit 0
        ;;
    v) skip_visualisations=true ;; # ...flag to skip static visualisations script (visualisations.R)
    s) skip_shiny_app=true ;; # ...flag to skip Shiny app script (youngbites.R)
    p) run_in_parallel=true ;; # ...flag to run visualisations.R and youngbites.R scripts in parallel
    d) keep_fields=true ;; # ...flag to keep food consumption fields in cleaned dataset
    g) save_svg=true ;; # ...flag to save static visualisations in SVG format
    i) shiny_gui=true ;; # ...flag to open Shiny app in GUI rather than browser
    a) ;; # ...recognise flag but do nothing (since it's for preprocess.sh)
    A) ;; # ...recognise flag but do nothing (since it's for preprocess.sh)
    *) # ...wildcard to recognise illegal flags and:
        echo "...that's a red flag!" 
        echo "Your specified flag is not recognised. The available flags are as follows:"
        show_help
        exit 1
        ;;
    esac
done


# Check for conflict: -p with -s or -v
# ...this would otherwise attempt parallel programming on skipped scripts

if $run_in_parallel; then
    if $skip_visualisations || $skip_shiny_app; then
        echo "Error: The -p flag cannot be used with -s or -v."
        echo "Run './jobscript.sh -h' for more information."
        exit 1
    fi
fi

# Check for conflict: -g with -v
# ...this would otherwise attempt to save SVGs of skipped visualisation script

if $skip_visualisations; then
    if $save_svg; then
        echo "Error: The -g flag cannot be used with -v."
        echo "Run './jobscript.sh -h' for more information."
        exit 1
    fi
fi

# Check for conflict: -i with -s
# ...this would otherwise attempt to open Shiny app in IDE when it's skipped

if $skip_shiny_app; then
    if $shiny_gui; then
        echo "Error: The -i flag cannot be used with -s."
        echo "Run './jobscript.sh -h' for more information."
        exit 1
    fi
fi

# Function to run a script and print elapsed time

run_and_time() {
    local start=$(date +%s)

    "$@" || { echo "Failed to run $1."; exit 1; }

    local end=$(date +%s)
    echo "Time elapsed for $1: $((end-start)) seconds."
}


# Set directory to where scripts are stored

cd code || { echo echo "Hmmm, can't step into 'code' directory. Did it wander off? Please make sure it's where it should be, as per README.md."; exit 1; }


# Run data processing script

echo "RUNNING DATA PROCESSING SCRIPT..."
# ...pass command line arguments to preprocess.sh
run_and_time bash preprocess.sh "$@" || { echo "Failed to run data processing script."; exit 1; }


# Run data wrangling script

echo "RUNNING DATA WRANGLING SCRIPT..."
run_and_time Rscript data_wrangling.R "$@" || { echo "Failed to run data wrangling script."; exit 1; }


# Remove old data

rm ../raw/merged.csv


# Function to run data visualisation script (this does not run the script itself)

run_visualisations() {
    echo "RUNNING DATA VISUALISATION SCRIPT..."
    # ...pass command line arguments to visualisations.R
    run_and_time Rscript visualisations.R "$@" || { echo "Failed to run data visualisation script."; exit 1; }
}


# Function to run Shiny app script (this does not run the script itself)

run_shiny_app() {
    echo "RUNNING SHINY APP SCRIPT..."
    # ...pass command line arguments to youngbites.R
    # ...no run_and_time call because the terminal will be pending when the Shiny app is running
    Rscript ../visualisations/shiny/youngbites.R "$@" # ...no error handling because Shiny app may still run even if there's an error
}


# Run visualisations and Shiny scripts based off -p flag

if $run_in_parallel; then # ...run in parallel if -p flag is specified
    if ! $skip_visualisations; then
        run_visualisations "$@" &
    fi
    if ! $skip_shiny_app; then
        run_shiny_app "$@" &
    fi
    wait # ...wait for all background processes to finish
else # ...run sequentially if -p flag is not specified
    if ! $skip_visualisations; then
        run_visualisations "$@"
    fi
    if ! $skip_shiny_app; then
        run_shiny_app "$@"
    fi
fi

# Delete Shiny-specific dataframe unless -s flag is specified

if ! $skip_shiny_app; then
echo "Removing shiny-specific data frame..."
    rm ../clean/data.rds
fi

# All scripts run

echo "All scripts run!"
echo ""
echo "Please check the 'clean' directory for the cleaned and merged dataset."


# ...visualisation completion message only if not skipped via -v flag

if ! $skip_visualisations; then
    echo ""
    echo "Please check the 'visualisations' directory for the static visualisations."
fi


# ...Shiny app completion message only if not skipped via -s flag

if ! $skip_shiny_app; then
    echo ""
    echo "If your Shiny app hasn't automatically launched, please check your browser or GUI settings."
fi
# -----------------------------------------------------------------------------
#                               END OF SCRIPT