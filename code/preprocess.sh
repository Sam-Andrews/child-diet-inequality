#!/usr/bin/env bash

# Parse command line options
# ...set default values if not specified
min_age=0
max_age=12

while getopts "a:A:" opt; do
    case "$opt" in
    a) min_age=$OPTARG ;;
    A) max_age=$OPTARG ;;
    *) ;;
    esac
done

# Set directory to where raw data is stored
cd ../raw

# Function to filter columns - [to remove from script!]
filter_columns() {
    local input_file=$1
    local output_file=$2
    local fields=$3
    echo "Filtering $input_file..."
    cut -d',' -f$fields $input_file > $output_file
    echo "...Complete."
}

# Function to sort file by unique identifier
sort_file() {
    local input_file=$1
    local output_file=$2
    echo "Sorting $input_file..."
    sort -k1,1 $input_file > $output_file # ...assumes unique identifier is first column
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

filter_by_age() {
    local input_file=$1
    local output_file=$2
    local min=$min_age
    local max=$max_age

    echo "Filtering for respondents between $min and $max years..."

    # Extract and preserve the header
    head -1 $input_file > $output_file

    # Filter the data, skipping the header
    # ...assumes 'age in years' is located in Column 6
    awk -F',' -v min="$min" -v max="$max" 'NR>1 && ($6 >= min && $6 <= max)' $input_file >> $output_file

    echo "...Complete."
}

# Function to remove duplicates
remove_duplicates() {
    local input_file=$1
    local output_file=$2
    echo "Detecting duplicate cases..."
    head -1 $input_file > header.csv
    tail -n +2 $input_file | sort -t',' -k1,1 -u | cat header.csv - > $output_file
    echo "...Complete."
}

# Function to remove trailing whitespace
remove_trailing_whitespace() {
    local input_file=$1
    local output_file=$2
    echo "Removing trailing whitespace..."
    sed 's/[[:space:]]*$//g' $input_file > $output_file
    echo "...Complete."
}

# Function to recode missing values
recode_missing_values() {
    local input_file=$1
    local output_file=$2
    echo "Recoding missing values..."
    awk -F, -v OFS=',' '{for(i = 1; i <= NF; i++) {if($i == 88 || $i == 99) $i = "NA";} print;}' $input_file > $output_file
    echo "...Complete."
}

## Main script

# Filter columns
#filter_columns DEMO_D.csv DEMO_D_cut.csv "1,5-7,9,11,12,14,16,18,20"
#filter_columns FFQRAW_D.csv FFQRAW_D_cut.csv "1,34-39,42,43,46,49,52,55,56-63,66-72,75,78,79,81,93,176,178-182,184,186,187"

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
rm DEMO_D_sorted.csv FFQRAW_D_sorted.csv merged_unclean.csv merged_age.csv merged_dup.csv merged_ws.csv header.csv
echo "...Complete."