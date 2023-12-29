# This script reads our merged dataset and performs the following wrangling
# tasks:
#
# Index creation:
# ... fruit consumption index
# ... vegetable consumption index
# ... processed sugar consumption index
#
# Creating dummy variables signifying whether respondent consumed fruit, veg
# and sugar at each response level
#
# Saving the cleaned study dataset in the `clean/` directory

# ----------------------------------------------------------------------------

# Source activate.R as a failsafe (should it not automatically run)

# ...define the path
sourcepath <- ("renv/activate.R")

# ...check if activate.R exists and source it
if (file.exists(sourcepath)) {
  source(sourcepath)
} else {
  stop("activate.R file not found. Please ensure it exists at ", sourcepath)
}


# Run libraries

renv::restore() # ...restore renv environment

suppressMessages({ # ...removes clutter in the terminal (doesn't hide errors)
  library(here) # ...for relative path file management
  library(dplyr) # ...for data wrangling
  library(tidyr) # ...for data manipulation
})


# Read command-line flags

args <- commandArgs(trailingOnly = TRUE)


## Read merged dataset

df <- read.csv(here::here("../raw", # ...file path to dataset
                          "merged.csv"), # ...dataset name
               header = TRUE, # ...read first row as header
               na.strings = "NA") # ...sets "NA" string to missing/NA

# ----------------------------------------------------------------------------

# Internal validation checks

print("Conducting internal validation checks...")

nrow_df1 <- nrow(df)

# ...check that 'age in months' is in line with 'age in years
df_age <- df %>%
  dplyr::mutate(RIDAGEMN_yr = RIDAGEMN / 12) %>% # ...divide age in months by 12
  dplyr::filter(abs(RIDAGEYR - RIDAGEMN_yr) < 1) %>% # ...filter out cases
  select(-RIDAGEMN, -RIDAGEMN_yr) # ...remove unneeded variables


# ...filter out cases with more than 10% missing data
df_missing <- df_age %>%
  # ...add new column that calculates the proportion of missing values per row
  mutate(prop_missing = rowSums(is.na(.)) / ncol(.)) %>%
  # ...filter out rows where the proportion of missing values > 10%
  filter(prop_missing <= 0.10) %>%
  # ...remove unneeded variable
  select(-prop_missing)


nrow_df2 <- nrow(df_age)


print(paste0("...Number of cases lost due to interval validation: ", 
             nrow_df1 - nrow_df2))


df <- df_missing

# ----------------------------------------------------------------------------

# Recode variables with more intuitive values
# Treat them as factors for plot ordering purposes.

print("Recoding variables...")

# Gender
# ...this is more appropriately a 'sex' variable; no gender-spectrum identities
#    were recorded.

df <- df %>%
  dplyr::mutate(RIAGENDR = factor(case_when(
    RIAGENDR == 1 ~ "Male",
    RIAGENDR == 2 ~ "Female"
  ), levels = c("Male", "Female")))

# Ethnicity
# ...combining some groups due to small subsamples

df <- df %>%
  dplyr::mutate(RIDRETH1 = factor(case_when(
    RIDRETH1 == 1 ~ "Mexican American",
    RIDRETH1 == 2 ~ "Other",
    RIDRETH1 == 3 ~ "White American",
    RIDRETH1 == 4 ~ "Black American",
    RIDRETH1 == 5 ~ "Other"
  ), levels = c("Mexican American", "Other Hispanic", "White American", 
                "Black American", "Other")))


# Household income
# ...combining groups due to small subsamples

df <- df %>%
  dplyr::mutate(INDHHINC = factor(case_when(
    INDHHINC == 1  ~ "Under $15,000",
    INDHHINC == 2  ~ "Under $15,000",
    INDHHINC == 3  ~ "Under $15,000",
    INDHHINC == 4  ~ "$15,000-$24,999",
    INDHHINC == 5  ~ "$15,000-$24,999",
    INDHHINC == 6  ~ "$25,000-$44,999",
    INDHHINC == 7  ~ "$25,000-$44,999",
    INDHHINC == 8  ~ "$45,000-$64,999",
    INDHHINC == 9  ~ "$45,000-$64,999",
    INDHHINC == 10 ~ "$65,000+",
    INDHHINC == 11 ~ "$65,000+"
  ), levels = c("Under $15,000", "$15,000-$24,999", "$25,000-$44,999",
                "$45,000-$64,999", "$65,000+")))


# Age groups

df <- df %>%
  dplyr::mutate(RIDAGEYR = factor(case_when(
    RIDAGEYR <= 4 ~ "4 and under",
    RIDAGEYR > 4 & RIDAGEYR <= 8 ~ "5 to 8",
    # ...need upper age cut-off in case user configures different age cut-offs
    #    in the command line:
    RIDAGEYR > 8 & RIDAGEYR < 13 ~ "9 and above"
  ), levels = c("4 and under", "5 to 8", "9 and above")))



# Household size
# ...combining groups due to small subsamples

df <- df %>%
  dplyr::mutate(DMDHHSIZ = factor(case_when(
    DMDHHSIZ == 1 | DMDHHSIZ == 2 | DMDHHSIZ == 3 ~ "1 to 3 members",
    DMDHHSIZ == 4 | DMDHHSIZ == 5 ~ "4 to 5 members",
    DMDHHSIZ == 6 | DMDHHSIZ == 7 ~ "6+ members"),
    levels = c("1 to 3 members",
               "4 to 5 members",
               "6+ members")))


# ----------------------------------------------------------------------------
# Function to produce index for a given range of columns

print("Constructive derived variables...")

make_index <- function(data, start_col, end_col) {
  
  # Find the indices of the start and end columns
  cols_indices <- which(names(data) %in% c(start_col, end_col))
  
  # Check if both columns are found
  if (length(cols_indices) != 2) {
    stop("Start or end column not found in the data frame.
         Make sure you've specified the correct data frame, start column,
         and end column.")
  }
  
  # Create a range of column names
  cols_range <- names(data)[min(cols_indices):max(cols_indices)]
  
  # Use dplyr to calculate the mean of non-NA values across the specified columns
  data %>%
    rowwise() %>%
    mutate(mean_value = mean(c_across(all_of(cols_range)), na.rm = TRUE)) %>%
    ungroup() %>%
    pull(mean_value)
}

# Call function for each of our column ranges

df$fruit_index <- make_index(df, "FFQ0016", "FFQ0027") # ...fruit index
df$veg_index <- make_index(df, "FFQ0028", "FFQ0057") # ...veg index
df$sugar_index <- make_index(df, "FFQ0112", "FFQ0120") # ...sugar index


# Below converts any `NaN` to `NA`. This stage is required for the Shiny app.

df[] <- lapply(df, function(x) { if(is.numeric(x)) { 
  x[is.nan(x)] <- NA }; return(x) })


# ----------------------------------------------------------------------------

## Create indicator of whether respondent consumes anything at each response 
## level for each of fruit, vegetable, and sugar variables.

# First, the function for fruit and veg

any_fruitveg <- function(data, start_col_name, end_col_name, name_prefix) {
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  data_slice <- data[, min(cols_range):max(cols_range)]
  
  for (i in 1:4) {
    var_name <- paste0(name_prefix, "_", i)
    data[[var_name]] <- apply(data_slice, 1, function(x) all(x <= i, 
                                                             na.rm = TRUE))
    data[[var_name]] <- factor(ifelse(data[[var_name]], "Yes", "No"))
  }
  
  return(data)
}


# Apply function to fruit and veg indices

df <- any_fruitveg(df, "FFQ0016", "FFQ0027", "fruit")
df <- any_fruitveg(df, "FFQ0028", "FFQ0057", "veg")


## Now a similar function for sugar consumption

extreme_sugar <- function(data, start_col_name, end_col_name, name_prefix) {
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  data_slice <- data[, min(cols_range):max(cols_range)]
  
  for (limit in 8:11) {
    var_name <- paste0(name_prefix, "_", limit)
    data[[var_name]] <- apply(data_slice, 1, function(x) any(x >= limit, na.rm = TRUE))
    data[[var_name]] <- factor(ifelse(data[[var_name]], "Yes", "No"))
  }
  
  return(data)
}


# Apply function to sugar variables

df <- extreme_sugar(df, "FFQ0112", "FFQ0120", "sugar")


# ----------------------------------------------------------------------------

## Produce dedicated data frame for Shiny app

print("Producing clean dataset...")

# Set 'natural language' names for variables (backticks allow for space chars)

shiny_df <- df %>%
  dplyr::mutate(`gender` = RIAGENDR,
                `age` = RIDAGEYR,
                `ethnicity` = RIDRETH1,
                `annual household income` = INDHHINC,
                `size of household` = DMDHHSIZ,
                `the fruit index` = fruit_index,
                `the vegetable index` = veg_index,
                `the sugar index` = sugar_index,
                `low fruit consumption` = fruit_4,
                `low vegetable consumption` = veg_4,
                `high sugar consumption` = sugar_9)


# Select only required variables for Shiny app
# ...this is important for app performance

new_shiny <- shiny_df %>%
  dplyr::select(fruit_index:`high sugar consumption`)

saveRDS(new_shiny, file = here::here("../clean", "data.rds"))

print("Data wrangling script fully executed.")


# ----------------------------------------------------------------------------

# Save cleaned 'study dataset' in the `clean/`
# ...user-set flags determine which fields are saved

if("-d" %in% args) {
  print("Saving full dataset to `clean/` directory")
  write.csv(df, file = here::here("../clean", "clean_data.csv"))
  
} else {
  print("Saving trimmed dataset to `clean/` directory")
  df <- df %>%
    dplyr::select(SEQN, RIAGENDR, RIDAGEYR, RIDRETH1, DMDHHSIZ, INDHHINC,
                  fruit_index, veg_index, sugar_index, fruit_1:sugar_11)
  
  write.csv(df, file = here::here("../clean", "clean_data.csv"))
}

# -----------------------------------------------------------------------------
#                               END OF SCRIPT