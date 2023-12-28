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
    RIDRETH1 == 2 ~ "Other",
    RIDRETH1 == 3 ~ "White American",
    RIDRETH1 == 4 ~ "Black American",
    RIDRETH1 == 5 ~ "Other"
  ), levels = c("Mexican American", "Other Hispanic", "White American", 
                "Black American", "Other")))

# Household income

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




# Whether child is in education
# Note that this has merged 'school' response options to create an 'in
# education / out of education' binary classifier

 df <- df %>%
   dplyr::mutate(DMDSCHOL = factor(case_when(
     DMDSCHOL == 1 ~ "In education",
     DMDSCHOL == 2 ~ "In education",
     DMDSCHOL == 3 ~ "Not in education"
   ), levels = c("In education", "Not in education")))


# Age groups

df <- df %>%
  dplyr::mutate(RIDAGEYR = factor(case_when(
    RIDAGEYR <= 4 ~ "4 and under",
    RIDAGEYR > 4 & RIDAGEYR <= 8 ~ "5 to 8",
    RIDAGEYR > 8 ~ "9 and above"
  ), levels = c("4 and under", "5 to 8", "9 and above")))



# Household size

table(df$DMDHHSIZ)

df <- df %>%
  dplyr::mutate(DMDHHSIZ = factor(case_when(
    DMDHHSIZ == 1 | DMDHHSIZ == 2 | DMDHHSIZ == 3 ~ "1 to 3 members",
    DMDHHSIZ == 4 | DMDHHSIZ == 5 ~ "4 to 5 members",
    DMDHHSIZ == 6 | DMDHHSIZ == 7 ~ "6+ members"),
    levels = c("1 to 3 members",
               "4 to 5 members",
               "6+ members")))

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
  
  # Calculate the sum of non-NA values for each row
  sum_non_na <- rowSums(data[, cols_seq, drop = FALSE], na.rm = TRUE)
  
  # Count the number of non-NA values for each row
  count_non_na <- apply(data[, cols_seq], 1, function(x) length(na.omit(x)))
  
  # Calculate the mean by dividing sum by count of non-NAs
  sum_non_na / count_non_na
}


## Call function for each of our column ranges

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


# Select only required variables

new_shiny <- shiny_df[, 69:79]

saveRDS(new_shiny, file = here::here("../clean", "data.rds"))

print("Data wrangling script fully executed.")

# ----------------------------------------------------------------------------
#                               END OF SCRIPT