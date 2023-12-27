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





# ----------------------------------------------------------------------------

## Run libraries

renv::restore() # ...restore renv environment

library(here) # ...for relative path file management
library(dplyr) # ...for data wrangling
library(tidyr) # ...for data manipulation

# for here() function, directory is child-diet-inequality/code

# ----------------------------------------------------------------------------

## Read merged dataset

df <- read.csv(here::here("../raw", # ...file path to dataset
                          "merged.csv"), # ...dataset name
               header = TRUE, # ...read first row as header
               na.strings = "NA") # ...sets "NA" string to missing/NA

# ----------------------------------------------------------------------------

# Recode variables with descriptive strings for visualisation.
# Treat them as factors for plot ordering purposes.

# Gender

df <- df %>%
  dplyr::mutate(RIAGENDR = factor(case_when(
    RIAGENDR == 1 ~ "Male",
    RIAGENDR == 2 ~ "Female"
  ), levels = c("Male", "Female")))

# Ethnicity

df <- df %>%
  dplyr::mutate(RIDRETH1 = factor(case_when(
    RIDRETH1 == 1 ~ "Mexican American",
    RIDRETH1 == 2 ~ "Other Hispanic",
    RIDRETH1 == 3 ~ "White American",
    RIDRETH1 == 4 ~ "Black American",
    RIDRETH1 == 5 ~ "Other"
  ), levels = c("Mexican American", "Other Hispanic", "White American", 
                "Black American", "Other")))

# Household income

df <- df %>%
  dplyr::mutate(INDHHINC = factor(case_when(
    INDHHINC == 1  ~ "$0 to $4,999",
    INDHHINC == 2  ~ "$5,000 to $9,999",
    INDHHINC == 3  ~ "$10,000 to $14,999",
    INDHHINC == 4  ~ "$15,000 to $19,999",
    INDHHINC == 5  ~ "$20,000 to $24,999",
    INDHHINC == 6  ~ "$25,000 to $34,999",
    INDHHINC == 7  ~ "$35,000 to $44,999",
    INDHHINC == 8  ~ "$45,000 to $54,999",
    INDHHINC == 9  ~ "$55,000 to $64,999",
    INDHHINC == 10 ~ "$65,000 to $74,999",
    INDHHINC == 11 ~ "$75,000 and Over",
    INDHHINC == 12 ~ NA,
    INDHHINC == 13 ~ NA
  ), levels = c("$0 to $4,999", "$5,000 to $9,999", "$10,000 to $14,999", 
                "$15,000 to $19,999", "$20,000 to $24,999", 
                "$25,000 to $34,999", "$35,000 to $44,999", 
                "$45,000 to $54,999", "$55,000 to $64,999", 
                "$65,000 to $74,999", "$75,000 and Over")))


# Whether child is in education
# Note that this has merged 'school' response options to create an 'in
# education / out of education' signifier

# df <- df %>%
#   dplyr::mutate(DMDSCHOL = factor(case_when(
#     DMDSCHOL == 1 ~ "In education",
#     DMDSCHOL == 2 ~ "In education",
#     DMDSCHOL == 3 ~ "Not in education"
#   ), levels = c("In education", "Not in education")))


# Age groups

df <- df %>%
  dplyr::mutate(RIDAGEYR = factor(case_when(
    RIDAGEYR <= 4 ~ "4 and under",
    RIDAGEYR > 4 & RIDAGEYR <= 8 ~ "5 to 8",
    RIDAGEYR > 8 ~ "9 and above"
  ), levels = c("4 and under", "5 to 8", "9 and above")))


# CItizenship status

# df <- df %>%
#   dplyr::mutate(DMDCITZN = factor(case_when(
#     DMDCITZN == 1 ~ "US Citizen",
#     DMDCITZN == 2 ~ "Not US Citizen",
#     DMDCITZN == 7 ~ NA
#   ), levels = c("US Citizen", "Not US Citizen")))


# ----------------------------------------------------------------------------
## Function to produce index for a range of columns

make_index <- function(data, start_col, end_col) {
  
  # Find the indices of the start and end columns
  cols_indices <- which(names(data) %in% c(start_col, end_col))
  
  # Check if both columns are found
  if (length(cols_indices) != 2) {
    stop("Start or end column not found in the data frame.
         Make sure you've specified the correct data frame, start column,
         and end column.")
  }
  
  # Create a sequence of indices
  cols_seq <- seq(from = min(cols_indices), to = max(cols_indices))
  
  # Calculate mean average for each column
  rowSums(data[, cols_seq, drop = FALSE], na.rm = TRUE) / length(cols_seq)
}

# ----------------------------------------------------------------------------

## Call function for each of our column ranges

df$fruit_index <- make_index(df, "FFQ0016", "FFQ0027") # ...fruit index
df$veg_index <- make_index(df, "FFQ0028", "FFQ0057") # ...veg index
df$sugar_index <- make_index(df, "FFQ0112", "FFQ0120") # ...sugar index


# ----------------------------------------------------------------------------

## Create indicator of whether respondent consumes anything at each response 
## level for each of fruit, vegetable, and sugar variables.

# First, the function for fruit and veg

any_fruitveg <- function(data, start_col_name, end_col_name, name_prefix) {
  # Identify the range of columns based on names
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  start_col <- min(cols_range)
  end_col <- max(cols_range)
  
  # Function to check if all values in a row are less than or equal to a specified limit
  check_limit <- function(row, limit) {
    all(row <= limit, na.rm = TRUE)
  }
  
  # Creating the first dummy variable
  # It checks if all values in the specified range are less than or equal to x
  
  var_name_1 <- paste0(name_prefix, "_1")
  data[[var_name_1]] <- apply(data[,start_col:end_col], 1, function(x) check_limit(x, 1))
  data[[var_name_1]] <- ifelse(data[[var_name_1]], "Yes", "No")
  data[[var_name_1]] <- factor(data[[var_name_1]]) # Convert to factor
  
  var_name_2 <- paste0(name_prefix, "_2")
  data[[var_name_2]] <- apply(data[,start_col:end_col], 1, function(x) check_limit(x, 2))
  data[[var_name_2]] <- ifelse(data[[var_name_2]], "Yes", "No")
  data[[var_name_2]] <- factor(data[[var_name_2]]) # Convert to factor
  
  var_name_3 <- paste0(name_prefix, "_3")
  data[[var_name_3]] <- apply(data[,start_col:end_col], 1, function(x) check_limit(x, 3))
  data[[var_name_3]] <- ifelse(data[[var_name_3]], "Yes", "No")
  data[[var_name_3]] <- factor(data[[var_name_3]]) # Convert to factor
  
  var_name_4 <- paste0(name_prefix, "_4")
  data[[var_name_4]] <- apply(data[,start_col:end_col], 1, function(x) check_limit(x, 4))
  data[[var_name_4]] <- ifelse(data[[var_name_4]], "Yes", "No")
  data[[var_name_4]] <- factor(data[[var_name_4]]) # Convert to factor
  
  return(data)
}

# Apply function to fruit and veg indices

df <- any_fruitveg(df, "FFQ0016", "FFQ0027", "fruit")
df <- any_fruitveg(df, "FFQ0028", "FFQ0057", "veg")


## Now a similar function for sugar consumption

extreme_sugar <- function(data, start_col_name, end_col_name, name_prefix) {
  # Identify the range of columns based on names
  cols_range <- which(names(data) %in% c(start_col_name, end_col_name))
  start_col <- min(cols_range)
  end_col <- max(cols_range)
  
  # Function to check if all values in a row are greater than or equal to a specified limit
  check_limit <- function(row, limit) {
    any(row >= limit, na.rm = TRUE)
  }
  
  # Create dummy variables for each threshold
  thresholds <- c(8, 9, 10, 11)
  for (limit in thresholds) {
    var_name <- paste0(name_prefix, "_", limit)
    data[[var_name]] <- apply(data[, start_col:end_col], 1, function(x) check_limit(x, limit))
    data[[var_name]] <- ifelse(data[[var_name]], "Yes", "No")
    data[[var_name]] <- factor(data[[var_name]]) # Convert to factor
  }
  
  return(data)
}

# Apply function to sugar variables

df <- extreme_sugar(df, "FFQ0112", "FFQ0120", "sugar")


# ----------------------------------------------------------------------------

## Output file to `clean` directory

write.csv(df, file = here::here("../clean", "clean_data.csv"))


# ----------------------------------------------------------------------------

## Produce dedicated data frame for Shiny app


# Set 'natural language' names for variables

shiny_df <- df %>%
  dplyr::mutate(`gender` = RIAGENDR,
                `age` = RIDAGEYR,
                `ethnicity` = RIDRETH1,
                `the fruit index` = fruit_index,
                `the vegetable index` = veg_index,
                `the sugar index` = sugar_index,
                `low fruit consumption` = fruit_4,
                `low vegetable consumption` = veg_4,
                `high sugar consumption` = sugar_9)


# Select only needed variables

new_shiny <- shiny_df[, 67:75]

saveRDS(new_shiny, file = here::here("../clean", "data.rds"))

print("Data wrangling script fully executed.")

# ----------------------------------------------------------------------------
#                               END OF SCRIPT