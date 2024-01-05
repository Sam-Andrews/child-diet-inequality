# This script produces two static visualisations based on our clean and 
# merged dataset.


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

clean_df <- read.csv(here::here("../clean", "clean_data.csv"))


# ----------------------------------------------------------------------------

# Plots

# First plot: Density plot to show distribution for indices

print("Creating first static data visualisation")

index_vis <- ggplot(clean_df) +
  # Add a density plot geom layer for index, with transparency (`alpha`)
  # levels for each
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
                    # Set order of index types in 'key':
                    breaks = c("Fruit index", "Vegetable index", 
                               "Sugar index")) +
  # Set labels
  labs(title = "Comparing diet consumption indices",
       # Subtitle to generate dynamically, depending on dataset age range
       subtitle = paste0("among those aged between ", 
                         min(clean_df$RIDAGEYR), # ...minimum age
                         " and ",
                         max(clean_df$RIDAGEYR)), # ...maximum age
       x = "Consumption index scores",
       y = "Proportion of respondents") +
  # Give x and y axes more interpretative scales
  scale_x_continuous(breaks = seq(0, 11, by = 1), limits = c(0, 11)) +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_bw() 


# Save visualisation to 'visualisations/' directory
# ...if -g flag is set, save as PNG & SVG. Else, save as just PNG.

if("-g" %in% args) {
  
  print("Saving first visualisation in PNG & SVG formats...")
  
  ggsave("index_vis.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 5, height = 3,
         # ...adjust dpi for resolution
         dpi = 800)
  
  ggsave("index_vis.svg", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 5, height = 3,
         # ...adjust dpi for resolution
         dpi = 800)
  
} else {
  
  print("Saving first visualisation in PNG format...")
  
  ggsave("index_vis.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 5, height = 3,
         # ...adjust dpi for resolution
         dpi = 800)
  
}

print("...Complete.")
# ---------------------------------------------------------------------------

# Second plot: prevelence of unhealthy consumption frequencies
# ...need to do some data wrangling first

print("Creating second static data visualisation")

# 'Pivot longer' to aggregate frequency groups and calculate proportions for each
clean_df_long <- clean_df %>%
  dplyr::select(fruit_1:fruit_4, veg_1:veg_4, sugar_9:sugar_11) %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "response") %>%
  dplyr::group_by(variable) %>%
  dplyr::summarise(yes_count = sum(response == "Yes", na.rm = TRUE),
            total_count = n(),
            yes_proportion = yes_count / total_count * 100) %>%
  ungroup()


# Define frequency labels for fruit, veg, and sugar
frequency_labels <- setNames(
  c(rep(c("Never", "1-6 times per year", "7-11 times per year", "once per month"), 2),
    "5-6 times per week", "1 time per day", "2 or more times per day"),
  c(paste0("fruit_", 1:4), paste0("veg_", 1:4), paste0("sugar_", 9:11))
)


# Assign frequency labels and food category
clean_df_long <- clean_df_long %>%
  dplyr::mutate(
    freq_label = factor(frequency_labels[variable], levels = unique(frequency_labels)),
    type = case_when(
      str_detect(variable, "fruit") ~ "Fruit",
      str_detect(variable, "veg") ~ "Vegetable",
      str_detect(variable, "sugar") ~ "Sugar"
    ),
    type = factor(type, levels = c("Fruit", "Vegetable", "Sugar"))
  )


# Plot
extreme_vis <- ggplot(clean_df_long, aes(x = freq_label, y = yes_proportion, 
                                         fill = type)) + 
  geom_bar(stat = "identity", position = position_dodge()) +
  # Add text labels to each bar:
  geom_text(aes(label = paste0(round(yes_proportion, 1), "%")), 
            position = position_dodge(width = 0.9),
            vjust = -0.5) +
            # Assign colours to each food category:
  scale_fill_manual(values = c("Fruit" = "#F4B860", "Vegetable" = "#DB7F8E", 
                               "Sugar" = "#6DA1B4")) +
  # Adjust the y-axis scale:
  scale_y_continuous(limits = c(0, 50), # ...fixes axis at 50%
                     breaks = seq(0, 100, by = 10),
                     # Append "%" on y-axis value labels
                     labels = function(x) paste0(sprintf("%.0f", x), "%")) + 
  theme_bw() +
  labs(title = "Extreme ends of fruit, vegetable, & sugar consumption",
       x = "Consumption frequency", 
       y = "Proportion of unhealthy consumption", 
       # Subtitle to generate dynamically, depending on dataset age range
       subtitle = paste0("among those aged between ", 
                         min(clean_df$RIDAGEYR), # ...minimum age
                         " and ",
                         max(clean_df$RIDAGEYR)), # ...maximum age
       ) +
  # Angle text for improved readability:
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_wrap(~ type, scales = "free_x") + # ...facet by food, veg, and sugar
  guides(fill = "none") # ...remove colour legend


## Save visualisation to visualisations directory
## ...if -g flag is set, save as PNG & SVG. Else, save as just PNG.

if("-g" %in% args) {
  print("Saving second visualisation in PNG and SVG formats...")
 
  ggsave("extreme_consumption.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 7, height = 5,
         # ...adjust dpi for resolution
         dpi = 800) 
  
  ggsave("extreme_consumption.svg", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 7, height = 5,
         # ...adjust dpi for resolution
         dpi = 800)
  
} else {
  
  print("Saving second visualisation in PNG format...")
  ggsave("extreme_consumption.png", plot = last_plot(), 
         path = here::here("../visualisations/images"),
         width = 7, height = 5,
         # ...adjust dpi for resolution
         dpi = 800)
}

print("...Complete.")
# -----------------------------------------------------------------------------
#                               END OF SCRIPT