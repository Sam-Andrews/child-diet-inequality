## This script produces two static visualisations based on our clean and 
## merged dataset.

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


# Run required libraries

renv::restore() # ...restore packages from renv.lock

suppressMessages({ # ...removes clutter in the terminal (doesn't hide errors)
  library(here) # ...for relative path file management
  library(dplyr) # ...for data wrangling
  library(ggplot2) # ...for data visualisation
  library(tidyr) # ...for data manipulation functions
  library(stringr) # ...for string manipulation functions
  library(svglite) # ...for saving in SVG format
})

# Read command-line flags

args <- commandArgs(trailingOnly = TRUE)


# Read dataframe

clean_df <- read.csv(here("../clean", "clean_data.csv"))


# ----------------------------------------------------------------------------

## Plots

# First plot: Density plot to show distribution for indices

print("Creating first static data visualisation")

index_vis <- ggplot(clean_df) +
  # Add a density plot geom layer for index, with transparency (`alpha`)
  # for each
  geom_density(aes(x = fruit_index, fill = "Fruit index"), alpha = 0.50,
               colour = NA) +
  geom_density(aes(x = veg_index, fill = "Vegetable index"), alpha = 0.45,
               colour = NA) +
  geom_density(aes(x = sugar_index, fill = "Sugar index"), alpha = 0.50,
               colour = NA) +
  # Set colours and auto-generate 'key'
  scale_fill_manual(name = "Index type", 
                    values = c("Fruit index" = "#F4B860",
                               "Vegetable index" = "#DB7F8E",
                               "Sugar index" = "#388697"),
                    # Set order of index types in 'key'
                    breaks = c("Fruit index", "Vegetable index", 
                               "Sugar index")) +
  # Set labels
  labs(title = "Comparing diet consumption indices",
       x = "Consumption index scores",
       y = "Proportion of respondents") +
  # Give x and y axes more interpretative scales
  scale_x_continuous(breaks = seq(0, 11, by = 1), limits = c(0, 11)) +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_bw() 


## Save visualisation to 'visualisations' directory
## ...if -g flag is set, save as SVG. Else, save as PNG.

if("-g" %in% args) {
  
  print("Saving first visualisation in SVG format...")
  
  ggsave("index_vis.svg", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 5, height = 3,
         dpi = 800)
  
} else {
  
  print("Saving first visualisation in PNG format...")
  
  ggsave("index_vis.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 5, height = 3,
         dpi = 800)
  
}


# ---------------------------------------------------------------------------

# Second plot: prevelence of unhealthy consumption frequency
# ...need to do some data wrangling first

print("Creating second static data visualisation")

# Pivot longer' to aggregate groups and calculate proportions for each category

clean_df_long <- clean_df %>%
  select(fruit_1:fruit_4, veg_1:veg_4, sugar_8:sugar_11) %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "response") %>%
  group_by(variable) %>%
  summarise(Yes_count = sum(response == "Yes", na.rm = TRUE), 
            Total_count = n()) %>%
  mutate(Yes_proportion = Yes_count / Total_count * 100) %>%
  ungroup()

# Original frequency labels for fruit and veg
frequency_labels <- c("Never", 
                      "1-6 times per year", 
                      "1 time per month",
                      "2-3 times per month")

# Sugar frequency labels
sugar_frequency_labels <- c("3-4 times per week", 
                            "5-6 times per week", 
                            "1 time per day",
                            "2 or more times per day")

# Create a new variable for frequency labels
clean_df_long$freq_label <- case_when(
  str_detect(clean_df_long$variable, "fruit") ~ factor(frequency_labels[match(gsub("\\D+", "", clean_df_long$variable), 1:4)], levels = frequency_labels),
  str_detect(clean_df_long$variable, "veg") ~ factor(frequency_labels[match(gsub("\\D+", "", clean_df_long$variable), 1:4)], levels = frequency_labels),
  str_detect(clean_df_long$variable, "sugar") ~ factor(sugar_frequency_labels[match(gsub("\\D+", "", clean_df_long$variable), 8:11)], levels = sugar_frequency_labels)
)

# Determine the type based on the variable name
clean_df_long$type <- case_when(
  str_detect(clean_df_long$variable, "fruit") ~ "Fruit",
  str_detect(clean_df_long$variable, "veg") ~ "Vegetable",
  str_detect(clean_df_long$variable, "sugar") ~ "Sugar"
)

# After determining the type, reorder the factor levels to make Sugar the last panel
clean_df_long$type <- factor(clean_df_long$type, levels = c("Fruit", 
                                                            "Vegetable", 
                                                            "Sugar"))


# Plotting with separate positions for each frequency label
extreme_vis <- ggplot(clean_df_long, aes(x = freq_label, y = Yes_proportion, 
                                         fill = type)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_text(aes(label = paste0(round(Yes_proportion, 1), "%")), 
            position = position_dodge(width = 0.9),
            vjust = -0.5) +
  scale_fill_manual(values = c("Fruit" = "#F4B860", "Vegetable" = "#DB7F8E", 
                               "Sugar" = "#6DA1B4")) +
  # Adjust the y-axis scale:
  scale_y_continuous(limits = c(0, 50), breaks = seq(0, 100, by = 10)) +
  theme_bw() +
  labs(x = "Consumption group", y = 
         "Proportion of unhealthy consumption", 
       title = "The extreme ends of fruit, veg, and sugar consumption") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_wrap(~ type, scales = "free_x") +
  guides(fill = "none") # ...remove colour legend


## Save visualisation to visualisations directory
## ...if -g flag is set, save as SVG. Else, save as PNG.

if("-g" %in% args) {
  print("Saving second visualisation in SVG format...")
  ggsave("extreme_consumption.svg", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 7, height = 5,
         dpi = 800)
} else {
  
  print("Saving second visualisation in PNG format...")
  ggsave("extreme_consumption.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 7, height = 5,
         dpi = 800)
}


# -----------------------------------------------------------------------------
#                               END OF SCRIPT