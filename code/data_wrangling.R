# This script reads our merged dataset and performs the following wrangling
# tasks:
#
# * Index creation:
# ... fruit consumption index
# ... vegetable consumption index
# ... processed sugar consumption index
#
# * Creating dummy variables signifying whether respondent consumed fruit, veg
# and sugar at each response level
#
# * Removing fields that are not required for subsequent scripts.
#
# * Saving the cleaned study dataset in the `clean/` directory and creating a
# Shiny-optimised dataset in the `clean/` directory.

# ----------------------------------------------------------------------------

suppressMessages({ # ...removes clutter in the terminal (doesn't hide errors)
  library(here) # ...for relative path file management
  library(dplyr) # ...for data wrangling
  library(tidyr) # ...for data manipulation
})


# Read command-line flags

args <- commandArgs(trailingOnly = TRUE)


# Read merged dataset

df <- read.csv(here::here("../raw", "merged.csv"))

# ----------------------------------------------------------------------------

# Filter for only required columns
# ...this is to save computation resources for the remainder of this pipeline

print("Filtering variables...")

# You can modify the below to include additional variables from the raw
# data as required

df <- df %>%
  dplyr::select(
    
    SEQN, # ...unique identifer
    
    # Socio-economic / demographic variables:
    
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

# Data integrity checks

print("Conducting data integrity checks...")

# Count number of observations before check
nrow_df1 <- nrow(df)

# Check that 'age in months' is consistent with 'age in years'

df_age <- df %>%
  dplyr::mutate(RIDAGEMN_yr = RIDAGEMN / 12) %>% # ...divide age in months by 12
  # ...remove cases where the absolute difference is greater than 1
  dplyr::filter(abs(RIDAGEYR - RIDAGEMN_yr) < 1) %>%
  dplyr::select(-RIDAGEMN, -RIDAGEMN_yr) # ...remove unneeded variables


# Filter out cases with 25% or more missing data

df_missing <- df_age %>%
  # ...add new column that calculates the proportion of missing values per row
  dplyr::mutate(prop_missing = rowSums(is.na(.)) / ncol(.)) %>%
  # ...keep rows where the proportion of missing values <= 25%
  dplyr::filter(prop_missing <= 0.25) %>%
  # ...remove unneeded variable
  dplyr::select(-prop_missing)

# Count number of observations after check
nrow_df2 <- nrow(df_missing)

# Print results of data integrity checks to the terminal
print(paste0("...Number of cases lost due to data integrity check: ", 
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
  # ...rowMeans() is a vectorised version of dplyr's rowwise() function
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


# Create indicator of respondent consumption at each response level for each 
# of fruit, vegetable, and sugar variables.

# First, the function for fruit and veg

freq_fruitveg <- function(data, start_col_name, end_col_name, name_prefix) {
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  data_slice <- data[, min(cols_range):max(cols_range)]
  
  for (i in 1:11) {
    var_name <- paste0(name_prefix, "_", i)
    data[[var_name]] <- apply(data_slice, 1, 
                              # ...check whether consumption is *no more than*
                              #    each frequency level:
                              function(x) all(x <= i, na.rm = TRUE))
    data[[var_name]] <- factor(ifelse(data[[var_name]], "Yes", "No"))
  }
  
  return(data)
}


# Apply function to fruit and veg indices

df <- freq_fruitveg(df, "FFQ0016", "FFQ0027", "fruit")
df <- freq_fruitveg(df, "FFQ0028", "FFQ0057", "veg")


# Now, a similar function for sugar consumption

freq_sugar <- function(data, start_col_name, end_col_name, name_prefix) {
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  data_slice <- data[, min(cols_range):max(cols_range)]
  
  for (i in 1:11) {
    var_name <- paste0(name_prefix, "_", i)
    data[[var_name]] <- apply(data_slice, 1, 
                              # ...check whether *any* consumption is at that 
                              #    frequency level or greater:
                              function(x) any(x >= i, na.rm = TRUE))
    data[[var_name]] <- factor(ifelse(data[[var_name]], "Yes", "No"))
  }
  
  return(data)
}


# Apply function to sugar variables

df <- freq_sugar(df, "FFQ0059", "FFQ0121", "sugar")

print("...Complete.")
# ----------------------------------------------------------------------------

# Food consumption columns are no longer needed. Drop them, unless user
# specifies otherwise via command-line flag

if("-d" %in% args) {
  print("Keeping unrequired fields as per user request...")
  
} else {
  print("Removing unrequired fields...")
  df <- df %>%
    dplyr::select(
      # Keep only the selected fields:
      SEQN, # ...unique identifier
      RIAGENDR, RIDAGEYR, RIDRETH1, DMDHHSIZ, INDHHINC, # ...demographics
                fruit_index, veg_index, sugar_index,  # ...indices
                fruit_1, fruit_2, fruit_3, fruit_4, # ...low fruit consumption
                veg_1, veg_2, veg_3, veg_4, # ...low vegetable consumption
                sugar_9, sugar_10, sugar_11) # ...high sugar consumption
}

print("...Complete.")
# ----------------------------------------------------------------------------

# Recode variables with more intuitive values
# ...treat them as factors
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
    INDHHINC %in% c(1, 2, 3)                             ~ "Under $15,000",
    INDHHINC %in% c(4, 5)                                ~ "$15,000-$24,999",
    INDHHINC %in% c(6, 7)                                ~ "$25,000-$44,999",
    INDHHINC %in% c(8, 9)                                ~ "$45,000-$64,999",
    INDHHINC %in% c(10, 11)                              ~ "$65,000+",
  ), levels = c("Under $15,000", "$15,000-$24,999", "$25,000-$44,999",
                "$45,000-$64,999", "$65,000+")))



# Age groups

df <- df %>%
  # ...saving age as a new variable, as we need to also keep the numeric form
  # for subsequent scripts
  dplyr::mutate(RIDAGEYR_factor = factor(case_when(
    RIDAGEYR <= 4                                        ~ "4 and under",
    RIDAGEYR > 4 & RIDAGEYR <= 8                         ~ "5 to 8",
    RIDAGEYR > 8 & RIDAGEYR < 13                         ~ "9 to 12",
    # ...the below is a failsafe in case the Shiny app does not hide age
    #    when the user selects custom age flags, as it should:
    TRUE                                                 ~ "Older"
  ), levels = c("4 and under", "5 to 8", "9 to 12", "Older")))


# Household size
# ...combining groups due to small subsamples

df <- df %>%
  dplyr::mutate(DMDHHSIZ = factor(case_when(
    DMDHHSIZ %in% 1:3                                 ~ "1 to 3 members",
    DMDHHSIZ %in% 4:5                                 ~ "4 to 5 members",
    DMDHHSIZ >= 6                                     ~ "6+ members"
  ), levels = c("1 to 3 members", "4 to 5 members", "6+ members")))


print("...Complete.")
# ----------------------------------------------------------------------------

# Produce dedicated data frame for Shiny app via 'rds' object
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
                  `age` = RIDAGEYR_factor,
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

write.csv(df, file = here::here("../clean", "clean_data.csv"))



print("Data wrangling script fully executed.")
# -----------------------------------------------------------------------------
#                               END OF SCRIPT