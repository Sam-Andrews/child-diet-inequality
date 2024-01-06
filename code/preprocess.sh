#!/usr/bin/env bash

# This script pre-processes the raw data files through merging by the SEQN field, filtering by age, 
# removing duplicates, and recoding missing values.
# It has been made modular (i.e., use of functions) to allow for easier debugging, testing, and 
# improved re-use value.

# Key assumptions of this script is that the SEQN field is in the first column of each raw dataset, 
# and that the age variable is in the 6th column of the merged dataset.


# Parse command line options
# ...set default values for age
# ...these will be overwritten if user supplies -a and -A flags

min_age=0
max_age=12

# Read in flags

while getopts "a:A:" opt; do
    case "$opt" in
    a) min_age=$OPTARG ;;
    A) max_age=$OPTARG ;;
    *) ;; # ...wildcard to recognise all other flags, but do nothing
    esac
done


# Set directory to where raw data is stored

cd ../raw || { echo "Hmmm, can't step into 'raw' directory. Did it wander off? Please make sure it's where it should be, as per README.md."; exit 1; }


# Function to sort file by unique identifier ("SEQN")
# ...function includes extra mechanisms to ignore the header because the 'sort' command
# can work differently between Windows WSL and native Linux distros

sort_file() {
    local input_file=$1
    local output_file=$2
    echo "Sorting $input_file..."

    # Extract the header and store it
    head -n 1 $input_file > header.csv

    # Sort the rest of the file, skipping the header
    tail -n +2 $input_file | sort -k1,1 > sorted_body.csv

    # Concatenate the header and the sorted body
    cat header.csv sorted_body.csv > $output_file

    echo "...Complete."
}


# Function to join files

join_files() {
    local file1=$1
    local file2=$2
    local output_file=$3
    echo "Joining $file1 and $file2..."
    join -t',' -1 1 -2 1 $file1 $file2 > $output_file
    echo "...Complete."
}


# Function to filter by age
# ...assumes age ("RIDAGEYR") is in Column 6 in the merged dataset

filter_by_age() {
    local input_file=$1
    local output_file=$2
    local min=$min_age
    local max=$max_age

    echo "Filtering for respondents between $min and $max years..."

    # Extract and preserve the header
    head -1 $input_file > $output_file

    # Filter the data, skipping the header
    # ...if needed, modify $6 to match the column number of the age variable:
    awk -F',' -v min="$min" -v max="$max" 'NR>1 && ($6 >= min && $6 <= max)' $input_file >> $output_file

    echo "...Complete."
}

# Function to remove duplicates based on the first column ("SEQN")

remove_duplicates() {
    local input_file=$1
    local output_file=$2
    echo "Removing duplicate cases..."
    head -1 $input_file > header.csv
    tail -n +2 $input_file | sort -t',' -k1,1 -u | cat header.csv - > $output_file
    echo "...Complete."
}

# Function to remove trailing whitespace

remove_trailing_whitespace() {
    local input_file=$1
    local output_file=$2
    echo "Removing trailing whitespace..."
    # ...regex to detect whitespace
    sed 's/[[:space:]]*$//g' $input_file > $output_file
    echo "...Complete."
}

# Function to recode missing values as 'NA'
# ...missing data are often coded as 88 or 99 in the raw data files

recode_missing_values() {
    local input_file=$1
    local output_file=$2
    echo "Recoding missing values..."
    awk -F, -v OFS=',' '{for(i = 1; i <= NF; i++) {if($i == 88 || $i == 99) $i = "NA";} print;}' $input_file > $output_file
    echo "...Complete."
}

## Run functions

# Sort files

sort_file DEMO_D.csv DEMO_D_sorted.csv
sort_file FFQRAW_D.csv FFQRAW_D_sorted.csv

# Join files

join_files DEMO_D_sorted.csv FFQRAW_D_sorted.csv merged_unclean.csv

# Filter by age

filter_by_age merged_unclean.csv merged_age.csv

# Remove duplicates

remove_duplicates merged_age.csv merged_dup.csv

# Remove trailing whitespace

remove_trailing_whitespace merged_dup.csv merged_ws.csv

# Recode missing values

recode_missing_values merged_ws.csv merged.csv

# Remove temporary files

echo "Removing temporary files..."
rm DEMO_D_sorted.csv FFQRAW_D_sorted.csv merged_unclean.csv merged_age.csv merged_dup.csv merged_ws.csv header.csv sorted_body.csv
echo "...Complete."
# -----------------------------------------------------------------------------
#                               END OF SCRIPT