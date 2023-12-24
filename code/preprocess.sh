#!/usr/bin/env bash

# This script joins data from the BMI, DEMO_D and FFQRAW_D datasets, and performs initial data cleaning.

# Set directory to where raw data is stored
cd ../raw

### COLUMN FILTERING --------------------------------------------------------------------------------------

echo "Filtering out unneeded fields..."

# Filter `DEMO_D.csv`
cut -d',' -f1,5-7,9,11,14,18,20 DEMO_D.csv > DEMO_D_cut.csv

# Filtering `FFQRAW_D.csv

# Column number cut off points

# 34 to 55 = fruit fields
# 56 to 93 = veg fields
# 167 to 187 = processed sugar fields

cut -d',' -f1,34-39,42,43,46,49,52,55,56-63,66-72,75,78,79,81,93,176,178-182,184,186,187 FFQRAW_D.csv > FFQRAW_D_cut.csv

echo "...Complete."


## MERGING DATA --------------------------------------------------------------------------------------------

echo "Merging datasets..."

echo "...BMI.csv has $(wc -l < BMI.csv) cases"
echo "...DEMO_D.csv has $(wc -l < DEMO_D.csv) cases"
echo "...FFQRAW_D.csv has $(wc -l < FFQRAW_D.csv) cases"


# Sort the files (code assumes `SEQN` is the first column in each dataset)

sort -k1,1 BMI.csv > BMI_sorted.csv
sort -k1,1 DEMO_D_cut.csv > DEMO_D_sorted.csv
sort -k1,1 FFQRAW_D_cut.csv > FFQRAW_D_sorted.csv

# Perform first 'inner join'
join -t',' -1 1 -2 1 BMI_sorted.csv DEMO_D_sorted.csv > first_join.csv

# Perform second 'inner join'
join -t',' -1 1 -2 1 first_join.csv FFQRAW_D_sorted.csv > merged_unclean.csv

echo "...Complete. $(($(wc -l < merged_unclean.csv) - 1)) respondents linked across datasets."

# ---------------------------------------------------------------------------------------------------------

## FILTER BY AGE - 12 AND UNDER 

echo "Filtering for respondents aged 12 and younger..."

awk -F',' '($4 <= 12)' merged_unclean.csv > merged_age.csv

echo "...Complete. Identified $(($(wc -l < merged_age.csv) - 1)) respondents aged 12 and below."


# ----------------------------------------------------------------------------------------------------

## REMOVING DUPLICATE CASES

echo "Detecting duplicate cases..."

# Extract header
head -1 merged_age.csv > header.csv

# Remove header, sort and deduplicate, then add header back
tail -n +2 merged_age.csv | sort -t',' -k1,1 -u | cat header.csv - > merged_dup.csv

# Count and display the number of rows
echo "...Complete. $(($(wc -l < merged_dup.csv) - 1)) cases remaining after removing duplicates."

# -----------------------------------------------------------------------------------------------


## Remove trailing whitespace

echo "Removing trailing whitespace..."

sed 's/[[:space:]]*$//g' merged_dup.csv > merged_ws.csv

echo "...Complete."

# ------------------------------------------------------------------------------------------------

## Recode missing values to NA (88 and 99)
## (Note: this is done after removing whitespace to avoid issues with trailing whitespace)

echo "Recoding missing values..."

# Loop through fields, replacing 88 and 99 with NA

awk -F, -v OFS=',' '{
    for(i = 1; i <= NF; i++) {
        if($i == 88 || $i == 99) $i = "NA";
    }
    print;
}' merged_ws.csv > merged.csv

echo "...Complete." 

# -------------------------------------------------------------------------------------------------




# Remove temporary files

echo "Removing temporary files..."

rm first_join.csv
rm BMI_sorted.csv 
rm DEMO_D_sorted.csv
rm merged_unclean.csv 
rm FFQRAW_D_sorted.csv 
rm merged_age.csv
rm merged_dup.csv
rm merged_ws.csv
rm merged_na.csv
rm header.csv
rm DEMO_D_cut.csv
rm FFQRAW_D_cut.csv

echo "...Complete."