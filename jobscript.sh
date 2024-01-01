#!/usr/bin/env bash

### This script can be used to automatically run the project's data processing pipeline ###
### It is intended to be run from the project's root directory ###

# Initialise flag variables

skip_visualisations=false
skip_shiny_app=false
run_in_parallel=false
save_svg=false
shiny_gui=false
keep_fields=false

# Function to display help via `./jobscript.sh -h`

show_help() {
    echo "Usage: ./$0 [-h -v -s -p -d -a -g -i -a -A]"
    echo ""
    echo "For more information about these flags, please see README_code.md."
    echo ""
    echo "Options:"
    echo "  -h    Display help"    
    echo "  -v    Skip static visualisations script (visualisations.R)"
    echo "  -s    Skip Shiny app script (youngbites.R)"
    echo "  -p    Run visualisations.R and Shiny app.R scripts in parallel (default is to run sequentially)."
    echo "  -d    Keep food consumption fields in clean_data.csv.
        Default is to remove non-derived fields from FFQRAW_D.csv for computational efficiency." # ...this is read by data_wrangling.R
    echo "  -g    Save static visualisations in SVG format (default is PNG)." # ...this is read by visualisations.R
    echo "  -i    Open Shiny app in GUI (default is to open in browser). 
        Note that some software (e.g. VSCode) may ignore this flag." # ...this is read by youngbites.R
    echo ""
    echo "Please specify the following flags *after* the above options, if applicable:"
    echo "  -a    Set minimum age (default is -a 0 for 0 years old). 
        Ensure there's a space between '-a' and your chosen age."  # ...this is read by preprocess.sh
    echo "  -A    Set maximum age (default is -A 12 for 12 years old). 
        Ensure there's a space between '-A' and your chosen age."  # ...this is read by preprocess.sh
}

# Parse command line options

while getopts "hvspaAgid" opt; do
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
    g) save_svg=true ;; # ...flag to save static visualisations in SVG format
    i) shiny_gui=true ;; # ...flag to open Shiny app in GUI rather than browser
    d) keep_fields=true ;; # ...flag to keep food consumption fields in cleaned dataset
    *)
        echo "...that's a red flag!" 
        echo "Your specified flag is not recognised. The available flags are as follows:"
        show_help
        exit 1
        ;;
    esac
done

#shift $((OPTIND-1))

# Check for conflict: -p with -s or -v
if $run_in_parallel; then
    if $skip_visualisations || $skip_shiny_app; then
        echo "Error: The -p flag cannot be used with -s or -v."
        echo "Run "./jobscript.sh -h" for more information."
        exit 1
    fi
fi

# Check for conflict: -g with -v
if $skip_visualisations; then
    if $save_svg; then
        echo "Error: The -g flag cannot be used with -v."
        echo "Run "./jobscript.sh -h" for more information."
        exit 1
    fi
fi

# Check for conflict: -i with -s
if $skip_shiny_app; then
    if $shiny_gui; then
        echo "Error: The -i flag cannot be used with -s."
        echo "Run './jobscript.sh -h' for more information."
        exit 1
    fi
fi

# Function to run a command and print elapsed time
run_and_time() {
    local start=$(date +%s)

    echo "RUNNING $1..."
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

# Function to run data visualisation script
run_visualisations() {
    echo "RUNNING DATA VISUALISATION SCRIPT..."
    # ...pass command line arguments to visualisations.R
    run_and_time Rscript visualisations.R "$@" || { echo "Failed to run data visualisation script."; exit 1; }
}

# Function to run Shiny app script
run_shiny_app() {
    echo "RUNNING SHINY APP SCRIPT..."
    # ...pass command line arguments to youngbites.R
    # ...no run_and_time call because the terminal will be pending when the Shiny app is running
    Rscript ../visualisations/shiny/youngbites.R "$@" # ...no error handling because Shiny app may still run even if there's an error
}


# Run visualisations and Shiny scripts based on flags
if $run_in_parallel; then
    if ! $skip_visualisations; then
        run_visualisations "$@" &
    fi
    if ! $skip_shiny_app; then
        run_shiny_app "$@" &
    fi
    wait # Wait for all background processes to finish
else
    if ! $skip_visualisations; then
        run_visualisations "$@"
    fi
    if ! $skip_shiny_app; then
        run_shiny_app "$@"
    fi
fi

# Delete Shiny-specific data unless -s flag is used

if ! $skip_shiny_app; then
echo "Removing shiny-specific data frame..."
    rm ../clean/data.rds
fi

# All scripts run

echo "All scripts run!"

echo ""
echo "Please check the 'clean' directory for the cleaned study dataset."

# ...visualisations completion message only if not skipped

if ! $skip_visualisations; then
    echo "Please check the 'visualisations' directory for the visualisations."
fi


# ...Shiny app completion message only if not skipped
if ! $skip_shiny_app; then
    echo ""
    echo "If your Shiny app hasn't automatically launched, please check your browser or GUI settings."
fi
# -----------------------------------------------------------------------------
#                               END OF SCRIPT