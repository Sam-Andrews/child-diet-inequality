## This script produces two static visualisations based on our clean and 
## merged dataset.

# ----------------------------------------------------------------------------

## Run libraries

library(here) # ...for relative path file management
library(dplyr) # ...for data wrangling
library(ggplot2) # ...for data visualisation
library(tidyr) # ...for data manipulation functions
library(stringr) # ...for string manipulation functions



## Read dataset

clean_df <- read.csv(here("../clean", "clean_data.csv"))

# ----------------------------------------------------------------------------

## Plots

# First plot: Density plot to show distribution for indices

index_vis <- ggplot(clean_df) +
  # Add a density plot geom layer for index
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

# +
#   theme(plot.title = element_text(size = 20, face = "bold"),
#         legend.title = element_text(size = 10, face = "bold"),
#         legend.text = element_text(size = 10))


## Save visualisation to 'visualisations' directory

ggsave("index_vis.png", plot = last_plot(), 
       path = here::here("../../visualisations"),
       width = 5, height = 3,
       dpi = 800)


# ---------------------------------------------------------------------------

# Second plot: Bar chart showing the proportion of children who consume less
# than a given amount of fruit or veg


### COMMENTED OUT: LEGACY VERSION OF PLOT ###

# First, we need to 'pivot longer' to aggregate groups and calculate
# proportions for each

# clean_df_long <- clean_df %>%
#   select(fruit_1:fruit_4, veg_1:veg_4) %>%
#   pivot_longer(cols = everything(), names_to = "variable", values_to = "response") %>%
#   group_by(variable) %>%
#   summarise(Yes_count = sum(response == "Yes", na.rm = TRUE), 
#             Total_count = n()) %>%
#   mutate(Yes_proportion = Yes_count / Total_count * 100) %>%
#   ungroup()
# 
# # Define the frequency labels without the type prefix
# frequency_labels <- c("Never", 
#                       "1-6 times per year", 
#                       "1 time per month",
#                       "2-3 times per month")
# 
# # Create a new variable for just the frequency labels
# clean_df_long$freq_label <- factor(frequency_labels[match(gsub("\\D+", "", clean_df_long$variable), 1:4)],
#                              levels = frequency_labels)
# 
# # Determine the type based on the variable name
# clean_df_long$type <- ifelse(str_detect(clean_df_long$variable, "fruit"), "Fruit", "Vegetable")
# 
# 
# # Plotting with separate positions for each frequency label
# ggplot(clean_df_long, aes(x = freq_label, y = Yes_proportion, 
#                     fill = type)) + # ...sets unique colours for each group
#   geom_bar(stat = "identity", position = "dodge") +
#   geom_text(aes(label = paste0(round(Yes_proportion, 1), "%")), 
#             position = position_dodge(width = 0.9), # Adjust to align with bars
#             vjust = -0.5,                          # Adjust vertical position
#             size = 4,                            # Adjust text size
#             fontface = "bold") +                                 
#   scale_fill_manual(values = c("Fruit" = "#F4B860", "Vegetable" = "#DB7F8E")) +
#   scale_y_continuous(limits = c(0, 20)) + # ...manually set the y axis to 20%
#   theme_bw() +
#   labs(x = "Consumption group", y = "Proportion of responses", 
#        title = "The extreme ends of fruit, veg, and sugar consumption") +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1, 
#                                    size = 12, face = "bold"),
#         plot.title = element_text(size = 20, face = "bold"),
#         axis.title.x = element_text(size = 10, face = "bold"),
#         axis.text.y = element_text(size = 12, face = "bold"),
#         axis.title.y = element_text(size = 12, face = "bold")) +
#   facet_wrap(~ type, scales = "free_x") + # ...facet by consumption group
# 




# ----------------


# First, we need to 'pivot longer' to aggregate groups and calculate
# proportions for each

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
            vjust = -0.5,
            fontface = "bold") +
  scale_fill_manual(values = c("Fruit" = "#F4B860", "Vegetable" = "#DB7F8E", 
                               "Sugar" = "#6DA1B4")) +
  # Adjust the y-axis scale:
  scale_y_continuous(limits = c(0, 50), breaks = seq(0, 100, by = 10)) +
  theme_bw() +
  labs(x = "Consumption group", y = "Proportion of responses", 
       title = "The extreme ends of fruit, veg, and sugar consumption") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  #                                  size = 12, face = "bold"),
  #       plot.title = element_text(size = 20, face = "bold"),
  #       axis.title.x = element_text(size = 10, face = "bold"),
  #       axis.text.y = element_text(size = 12, face = "bold"),
  #       axis.title.y = element_text(size = 12, face = "bold")) +
  facet_wrap(~ type, scales = "free_x") +
  guides(fill = "none") # ...remove colour legend


## Save visualisation to visualisations directory

ggsave("extreme_consumption.png", plot = last_plot(), 
       path = here::here("../../visualisations"),
       width = 7, height = 5,
       dpi = 800)


# ---------------------------------------------------------------------------


print("Visualisation script fully executed.")