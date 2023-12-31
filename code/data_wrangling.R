# This script reads our merged dataset and performs the following wrangling
# tasks:
#
# *Index creation:
# ... fruit consumption index
# ... vegetable consumption index
# ... processed sugar consumption index
#
# *Creating dummy variables signifying whether respondent consumed fruit, veg
# and sugar at each response level
#
# *Removing volumns
#
# *Saving the cleaned study dataset in the `clean/` directory

# ----------------------------------------------------------------------------

# Source activate.R as a failsafe (should it not automatically run)

# ...the below might report that the script is "out of sync with the lock file". 
#   This error can be ignored, as it is just an artifact of the failsafe.

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


# Read merged dataset

df <- read.csv(here::here("../raw", # ...file path to dataset
                          "merged.csv"), # ...dataset name
               header = TRUE, # ...read first row as header
               na.strings = "NA") # ...sets "NA" string to missing/NA


# ----------------------------------------------------------------------------

# Filter for only required columns
# ...this is to save computation resources for the remainder of this pipeline

print("Filtering variables...")

# You can modify the below to include additional variables from the raw
# data as required

df <- df %>%
  dplyr::select(
    
    SEQN, # ...unique identifer
    
    # Socio-economic variables:
    
    RIAGENDR, # ...gender
    RIDAGEYR, # ...age in years
    RIDAGEMN, # ...age in months (used for internal validation below)
    DMDHHSIZ, # ...household size
    INDHHINC, # ...household income
    RIDRETH1, # ...ethnicity
    
    # Fruit:

    FFQ0016, # ...apples
    FFQ0017, # ...pears
    FFQ0018, # ...bananas
    FFQ0019, # ...pineapples
    FFQ0020, # ...dried fruit
    FFQ0022, # ...grapes
    FFQ0027, # ...any other fruit
    
    # Vegetables:
    
    FFQ0028, # ...cooked greens
    FFQ0029, # ...raw greens
    FFQ0030, # ...coleslaw
    FFQ0031, # ...sauerkraut
    FFQ0032, # ...carrots
    FFQ0033, # ...string beans
    FFQ0034, # ...peas
    FFQ0036, # ...broccoli
    FFQ0037, # ...cauliflower
    FFQ0038, # ...mixed veg
    FFQ0039, # ...onions
    FFQ0040, # ...peppers
    FFQ0041, # ...cucumbers
    FFQ0044, # ...lettuce salad
    FFQ0046, # ...sweet potatoes
    FFQ0056, # ...cooked dried beans
    FFQ0057, # ...any other vegetable
    
    # High-sugar items:
    
    FFQ0059, # ...pancakes
    FFQ0101, # ...biscuits
    FFQ0104, # ...popcorn
    FFQ0112, # ...ice cream
    FFQ0113, # ...pudding
    FFQ0114, # ...cake
    FFQ0115, # ...cookies
    FFQ0116, # ...doughnuts
    FFQ0117, # ...sweet muffins
    FFQ0118, # ...fruit crisp (i.e. fruit crumble)
    FFQ0119, # ...pie
    FFQ0120, # ...chocolate
    FFQ0121 # ...other candy
  )

print("...Complete.")

# ----------------------------------------------------------------------------

# Internal validation checks

print("Conducting internal validation checks...")

nrow_df1 <- nrow(df)

# Check that 'age in months' is in line with 'age in years'

df_age <- df %>%
  dplyr::mutate(RIDAGEMN_yr = RIDAGEMN / 12) %>% # ...divide age in months by 12
  # ...filter out cases where the absolute difference is no greater than 1
  dplyr::filter(abs(RIDAGEYR - RIDAGEMN_yr) < 1) %>%
  select(-RIDAGEMN, -RIDAGEMN_yr) # ...remove unneeded variables


# Filter out cases with 25% or more missing data

df_missing <- df_age %>%
  # ...add new column that calculates the proportion of missing values per row
  mutate(prop_missing = rowSums(is.na(.)) / ncol(.)) %>%
  # ...filter out rows where the proportion of missing values > 10%
  filter(prop_missing <= 0.25) %>%
  # ...remove unneeded variable
  select(-prop_missing)


nrow_df2 <- nrow(df_missing)


print(paste0("...Number of cases lost due to interval validation: ", 
             nrow_df1 - nrow_df2))

# Make validated responses the new 'df'

df <- df_missing

print("...Complete.")

# ----------------------------------------------------------------------------

# Produce derived variables

print("Constructing derived variables...")

# Function to produce an index for a given range of columns

make_index <- function(data, start_col, end_col) {
  # ...locate start and end columns
  cols_indices <- which(names(data) %in% c(start_col, end_col))
  
  # ...check if both columns are found
  if (length(cols_indices) != 2) {
    stop("Start or end column not found in the data frame.")
  }
  
  # ...create a range of column indices
  cols_range <- min(cols_indices):max(cols_indices)
  
  # ...calculate the mean of non-NA values across the specified columns
  rowMeans(data[, cols_range], na.rm = TRUE)
}


# Call function for each of our column ranges

df$fruit_index <- make_index(df, "FFQ0016", "FFQ0027") # ...fruit index
df$veg_index <- make_index(df, "FFQ0028", "FFQ0057") # ...veg index
df$sugar_index <- make_index(df, "FFQ0059", "FFQ0121") # ...sugar index


# Convert any `NaN` to `NA`. This is required for the Shiny app.

df[] <- lapply(df, function(x) {
  if (is.numeric(x)) {
    x[is.nan(x)] <- NA
  }
  x
})



# Create indicator of whether respondent consumes anything at each response 
# level for each of fruit, vegetable, and sugar variables.

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


# Now, a similar function for sugar consumption

extreme_sugar <- function(data, start_col_name, end_col_name, name_prefix) {
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  data_slice <- data[, min(cols_range):max(cols_range)]
  
  for (i in 8:11) {
    var_name <- paste0(name_prefix, "_", i)
    data[[var_name]] <- apply(data_slice, 1, function(x) any(x >= i, 
                                                             na.rm = TRUE))
    data[[var_name]] <- factor(ifelse(data[[var_name]], "Yes", "No"))
  }
  
  return(data)
}


# Apply function to sugar variables

df <- extreme_sugar(df, "FFQ0059", "FFQ0121", "sugar")

print("...Complete.")
# ----------------------------------------------------------------------------

# Food consumption columns are no longer needed. Drop them, unless user
# specifies otherwise via command-line flag

if("-d" %in% args) {
  print("Keeping unrequired fields as per user request...")
  
} else {
  print("Removing unrequired fields...")
  df <- df %>%
    dplyr::select(SEQN, RIAGENDR, RIDAGEYR, RIDRETH1, DMDHHSIZ, INDHHINC,
                  fruit_index, veg_index, sugar_index, fruit_1:sugar_11)
}
print("...Complete.")
# ----------------------------------------------------------------------------

# Recode variables with more intuitive values
# ...treat them as factors for plot ordering purposes.
# ...specify levels to determine plot order

print("Recoding variables...")

# Gender

df <- df %>%
  dplyr::mutate(RIAGENDR = factor(case_when(
    RIAGENDR == 1                                        ~ "Male",
    RIAGENDR == 2                                        ~ "Female"
    
  ), levels = c("Male", "Female")))


# Ethnicity
# ...combining some groups due to small subsamples

df <- df %>%
  dplyr::mutate(RIDRETH1 = factor(case_when(
    RIDRETH1 == 1                                        ~ "Mexican American",
    RIDRETH1 == 2                                        ~ "Other",
    RIDRETH1 == 3                                        ~ "White American",
    RIDRETH1 == 4                                        ~ "Black American",
    RIDRETH1 == 5                                        ~ "Other"
    
  ), levels = c("Mexican American", "White American", 
                "Black American", "Other")))


# Household income
# ...combining groups due to small subsamples

df <- df %>%
  dplyr::mutate(INDHHINC = factor(case_when(
    INDHHINC == 1  | INDHHINC == 2 | INDHHINC == 3       ~ "Under $15,000",
    INDHHINC == 4  | INDHHINC == 5                       ~ "$15,000-$24,999",
    INDHHINC == 6  | INDHHINC == 7                       ~ "$25,000-$44,999",
    INDHHINC == 8  | INDHHINC == 9                       ~ "$45,000-$64,999",
    INDHHINC == 10 | INDHHINC == 11                      ~ "$65,000+"
    
  ), levels = c("Under $15,000", "$15,000-$24,999", "$25,000-$44,999",
                "$45,000-$64,999", "$65,000+")))


# Age groups

df <- df %>%
  dplyr::mutate(RIDAGEYR = factor(case_when(
    RIDAGEYR <= 4                                        ~ "4 and under",
    RIDAGEYR > 4 & RIDAGEYR <= 8                         ~ "5 to 8",
    # ...need upper age limit in case user configures different age
    #    cut-offs in the command line
    RIDAGEYR > 8 & RIDAGEYR < 13                         ~ "9 and above"
    
  ), levels = c("4 and under", "5 to 8", "9 and above")))



# Household size
# ...combining groups due to small subsamples

df <- df %>%
  dplyr::mutate(DMDHHSIZ = factor(case_when(
    DMDHHSIZ == 1 | DMDHHSIZ == 2 | DMDHHSIZ == 3        ~ "1 to 3 members",
    DMDHHSIZ == 4 | DMDHHSIZ == 5                        ~ "4 to 5 members",
    DMDHHSIZ == 6 | DMDHHSIZ == 7                        ~ "6+ members"
    
  ), levels = c("1 to 3 members", "4 to 5 members", "6+ members")))

print("...Complete.")
# ----------------------------------------------------------------------------

# Produce dedicated data frame for Shiny app
# ...this is to preserve factor levels and place space characters in column
#    names (so that the columns are in 'natural language' in the Shiny app)

# This section will be skipped if user skips youngbites.R script via the
# command line

if("-s" %in% args) {
  print("Skipping Shiny-optimised data frame...")
  
} else {
  print("Creating Shiny-optimised data frame...")
  shiny_df <- df %>%
    # Set 'natural language' variable names (backticks allow for space chars)
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
  saveRDS(shiny_df, file = here::here("../clean", "data.rds"))
  print("...Complete.")
}


# ----------------------------------------------------------------------------

# Save final study dataset in the `clean/` directory

print("Producing clean study dataset...")

write.csv(df, file = here("../clean", "clean_data.csv"))



print("Data wrangling script fully executed.")
# -----------------------------------------------------------------------------
#                               END OF SCRIPT