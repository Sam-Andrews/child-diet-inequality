# This script contains the source code for the Young Bites Shiny app. 
# If the app does not automatically launch via the command-line, you may be able
# to launch it manually by running the script in R Studio. 

# Note that the terminal may state that specified icon names do not 'correspond
# to any known icon'. This is because the icons are from an external library
# ('font-awesome') and can be ignored.


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
  library(shiny) # ...for main Shiny elements
  library(shinydashboard) # ...for dashboard set-up
  library(ggplot2) # ...for the plot server logic
  library(dplyr) # ...for data wrangling
  library(shinyWidgets) # ...for special widgets
  library(DT) # ...for data table management
  library(here) # ...for relative file path management
})

# Read command-line flags

args <- commandArgs(trailingOnly = TRUE)


# Read dataframe

shiny_df <- readRDS(here::here("../clean", "data.rds"))


# Set colours for plotting

col_1 <- "#F4B860"
col_2 <- "#388697"
col_3 <- "#DB7F8E"
col_4 <- "#9DBF9E"
col_5 <- "#FAA275"
col_6 <- "#BE97C6"
col_7 <- "#5C374C"
col_8 <- "#808F4D"

colour_palette <- c(col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8)


# Set colour-blindness-friendly colours for plotting

cb_col1 <- "#CE78A7"
cb_col2 <- "#009F73"
cb_col3 <- "#E8A014"
cb_col4 <- "#0070B1"
cb_col5 <- "#F1E646"
cb_col6 <- "#D85E11"
cb_col7 <- "#4EB3E8"
cb_col8 <- "#363537"



cb_colour_palette <- c(cb_col1, cb_col2, cb_col3, cb_col4, cb_col5, cb_col6,
                       cb_col7, cb_col8)



# ---------------------------------- UI ---------------------------------------

ui <- dashboardPage(
  
  ## Header
  
  dashboardHeader(title = "Young Bites App"),
  
  ## Theme
  
  skin = "blue",
  
  
  ## Sidebar
  ## ...these elements will control the variable selection options
  dashboardSidebar(
    # ...outcomVar is the outcome variable
    selectInput("outcomeVar", "I want to see how...", 
                choices = c(
                  "the fruit index",
                  "the vegetable index",
                  "the sugar index",
                  "low fruit consumption",
                  "low vegetable consumption",
                  "high sugar consumption"
                )),
    # ...compareVar sets the demographic to compare across
    selectInput("compareVar", "changes by...", 
                choices = c(
                  "gender",
                  "ethnicity",
                  "annual household income",
                  "size of household",
                  # Add age, but only if user has not set custom age flags
                  if("-a" %in% args || "-A" %in% args) {
                    # (no age variable if flag is set)
                  } else {
                    "age"
                  }
                )),
    # ...dodgeVar sets the demographic to base ggplot's 'dodge' on
    selectInput("dodgeVar", "and compares across...", 
                choices = c(
                  "nothing", # ...has no corresponding server logic
                  "gender",
                  "ethnicity",
                  "annual household income",
                  "size of household",
                  # Add age, but only if user has not set custom age flags
                  if("-a" %in% args || "-A" %in% args) {
                    # (no age variable if flag is set)
                  } else {
                    "age"
                  }
                ), selected = "nothing"),
    
    # Add a colour-blindness toggle
    tags$h5("Colourblind-friendly mode", class = "text-center"),
    
    # ...wrap the switchInput in a div to centre it
    div(
      switchInput(
        inputId = "Id018",
        label = "<i class=\"fa fa-thumbs-up\"></i>"
      ),
      style = "text-align: center;"  # ...this will centre the switch
    )
  ),
  
  
  # Main body
  
  dashboardBody(
    
    fluidRow(
      
      # Median fruit index box
      valueBoxOutput("fruitBox"),
      
      # Median veg index box
      valueBoxOutput("vegBox"),
      
      # Median sugar index box
      valueBoxOutput("sugarBox"),
      
      
      # Plot box
      box(title = "Chart", status = "primary", solidHeader = FALSE, 
          plotOutput("plot1", height = 400), width = 6),
      
      
      # Data table box
      box(title = "Data table", status = "warning", solidHeader = FALSE,
          DTOutput("dataTable"), width = 6), 
      
      
      # "Variable guide" box
      tabBox(
        title = "Variable guide",
        id = "tabset1", height = "400px", width = 6,
        # Using HTML for better text formatting
        tabPanel("Indices", 
                 HTML("The NHANES survey contained a simple scoring system for food consumption:
  <ul>
    <li>1  -  never</li>
    <li>2  -  1-6 times per year</li>
    <li>3  -  7-11 times per year</li>
    <li>4  -  1 time per month</li>
    <li>5  -  2-3 times per month</li>
    <li>6  -  1 time per week</li>
    <li>7  -  2 times per week</li>
    <li>8  -  3-4 times per week</li>
    <li>9  -  5-6 times per week</li>
    <li>10  -  1 time per day</li>
    <li>11  -  2+ times per day</li>
  </ul>
This dashboard's index variables averaged out these scores for each respondent,
within fruit, veg, and sugar-related food categories.")
                 
        ), tabPanel("Extreme consumption groups", 
                    HTML("'Extreme consumption groups' were constructed slightly 
                    differently between fruit/veg and sugar.
     <br>
     <br>
     For fruit and veg, a child is counted as part of the 'low consumption 
     group' if they consume no fruit/veg more than once per month.
     <br>
     <br>
     For sugar, a child is part of the 'high consumption group' if they consume
     any high-sugar product at least 5-6 times per week.")),
        tabPanel("Which should I use?",
                 HTML("This depends on your goals - the two sets of variables
      are useful in slightly different contexts.
      <br>
      <br>
      Index variables offer us a 'snapshot'. They are good at showing a bigger 
      picture of dietary habits within particular demographics, but aren't 
      always useful for identifying vulnerable groups. This is because if a 
      particular demographic contains many <em>healthy</em> eaters as well as many 
      <em>unhealthy</em> eaters, their score could average out somewhere down the 
      middle.
      <br>
      <br>
      On the other hand, 'extreme consumption' variables are geared towards
      identifying vulnerable demographics, but do not tell us anything about
      the frequency of <em>healthy</em> consumption within these groups. 
      Therefore, it's important not to generalise what these variables tell us 
      about particular demographics."))
      ),
    ),
  ),
)




# ----------------------------- SERVER LOGIC ---------------------------------


server <- function(input, output, session) {
  
  
  # Data box 1: Median fruit index  
  
  output$fruitBox <- renderValueBox({
    # Calculate the median fruit index
    avg_fruit <- round(median(shiny_df$`the fruit index`, 
                              na.rm = TRUE), digits = 2)
    valueBox(
      avg_fruit, "...median fruit index", 
      icon = icon("fa-sharp fa-solid fa-lemon", lib = "font-awesome"),
      color = # ...colo(u)r argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "yellow"
        } else {"olive"}
    )
  })
  
  
  # Data box 2: Median veg index  
  
  output$vegBox <- renderValueBox({
    # Calculate the average veg index
    avg_veg <- round(median(shiny_df$`the vegetable index`, 
                            na.rm = TRUE), digits = 2)
    valueBox(
      avg_veg, "...median vegetable index", 
      icon = icon("fa-sharp fa-solid fa-carrot", lib = "font-awesome"),
      color = # ...colo(u)r argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "red"
        } else {"aqua"}
      
    )
  })
  
  
  # Data box 3: Average sugar index  
  
  output$sugarBox <- renderValueBox({
    # Calculate the average sugar index
    avg_sugar <- round(median(shiny_df$`the sugar index`, 
                              na.rm = TRUE), digits = 2)
    valueBox(
      avg_sugar, "...median sugar index", 
      icon = icon("fa-sharp fa-solid fa-cubes-stacked", lib = "font-awesome"),
      color = # ...colo(u)r argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "purple"
        } else {"maroon"}
      
    )
  })
  
  
  
  # Plot
  # ... the below logic processes the variable selection options based off user-input.
  # ... input$outcomeVar, input$compareVar and input$dodgeVar all correspond
  #     to the UI elements in the sidebar

  #     In order to function, this section requires that the server logic differentiates
  #     between factor and non-factor variables. This is to avoid errors.
  
  output$plot1 <- renderPlot({
    req(input$outcomeVar, input$compareVar)
    
    
    # Define data frame, filtering out NAs
    data <- shiny_df %>%
      dplyr::filter(!is.na(.data[[input$outcomeVar]]), 
                    !is.na(.data[[input$compareVar]]))
    
    # Additional filter if dodgeVar is not "nothing"
    if(input$dodgeVar != "nothing") {
      data <- data %>%
        dplyr::filter(!is.na(.data[[input$dodgeVar]]))
    }
    
    # Define compareVar and dodgeVar
    compareVar <- paste0("`", input$compareVar, "`")
    dodgeVar <- if(!is.null(input$dodgeVar) && input$dodgeVar != "nothing") paste0("`", input$dodgeVar, "`") else NULL
    
    # Determine the variable to use for filling
    fillVar <- if(dodgeVar == "nothing" || is.null(dodgeVar)) compareVar else dodgeVar
    
    # Check if the outcome variable is a factor
    if(is.factor(data[[input$outcomeVar]])) {
      # Group by compareVar and by dodgeVar (if dodgeVar is specified)
      # ...(`rlang::syms()` is used to handle space characters in strings)
      group_vars <- rlang::syms(c(input$compareVar, if (!is.null(dodgeVar)) input$dodgeVar))
      data <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(YesProportion = mean(as.numeric(.data[[input$outcomeVar]] == "Yes"), na.rm = TRUE))
      
      # Initialise the plot object for factor outcomeVar
      p <- ggplot(data, aes_string(x = compareVar, y = "YesProportion", fill = fillVar)) +
        # ...if statement for colourblindness-friendly mode:
        if(input$Id018 == TRUE) {
          scale_fill_manual(values = cb_colour_palette)
        } else {
          scale_fill_manual(values = colour_palette)
        }
      
      
      # Modify the plot for factor outcomeVar
      p <- p +
        geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
        scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
        labs(y = "Proportion of unhealthy consumption", x = input$compareVar) +
        theme_bw() +
        # ...to avoid overlapping x axis text:
        theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))
    } else {  # For continuous outcomeVar...
      outcomeVar <- paste0("`", input$outcomeVar, "`")
      
      # Initialise the plot object for continuous outcomeVar
      p <- ggplot(data, aes_string(x = compareVar, y = outcomeVar, fill = fillVar)) +
        # ...if statement for colourblindness-friendly mode:
        if(input$Id018 == TRUE) {
          scale_fill_manual(values = cb_colour_palette)
        } else {
          scale_fill_manual(values = colour_palette)
        }
      
      # For continuous outcomeVar, display the median for the index
      p <- p + 
        geom_bar(stat = "summary", fun = "median", position = position_dodge(width = 0.9)) +
        labs(y = "Median Index Score", x = input$compareVar) +
        theme_bw() +
        # ...to avoid overlapping x axis text:
        theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))
    }
    
    # Print plot object
    print(p)
  })
  
  
  # Data table
  # ...data table should mirror the server logic of the 'plot'
  
  
  output$dataTable <- renderDT({
    req(input$outcomeVar, input$compareVar)
    
    data <- shiny_df
    
    # Exclude rows with missing dodgeVar values if dodgeVar is selected and not set to "nothing"
    if(!is.null(input$dodgeVar) && input$dodgeVar != "nothing") {
      data <- data %>% dplyr::filter(!is.na(.data[[input$dodgeVar]]))
    }
    # Similarly, exclude rows with missing compareVar values if compareVar is selected
    if(!is.null(input$compareVar) && input$compareVar != "nothing") {
      data <- data %>% dplyr::filter(!is.na(.data[[input$compareVar]]))
    }
    
    # Prepare variable names for grouping
    compareVar <- paste0("`", input$compareVar, "`")
    dodgeVar <- if(!is.null(input$dodgeVar) && input$dodgeVar != "nothing") paste0("`", input$dodgeVar, "`") else NULL
    
    # Define grouping variables dynamically based on the presence of dodgeVar
    group_vars <- if (!is.null(dodgeVar)) {
      rlang::syms(c(input$compareVar, input$dodgeVar))
    } else {
      rlang::syms(c(input$compareVar))
    }
    
    # Create a summary table based on the type of the outcome variable
    if(is.factor(data[[input$outcomeVar]])) {
      # For factor variables, calculate proportion and count for extreme
      # consumption signifiers
      data_summary <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(`Proportion (%)` = round(100 * mean(as.numeric(.data[[input$outcomeVar]] == "Yes"), na.rm = TRUE), 1),
                         Count = n(),
                         .groups = 'drop') # ...drop grouping for summary table
    } else {
      # For non-factor variables, calculate median and count for indices
      outcomeVar <- paste0("`", input$outcomeVar, "`")
      data_summary <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(Median = round(median(.data[[input$outcomeVar]], na.rm = TRUE), 1),
                         Count = n(),
                         .groups = 'drop') # Drop grouping for summary table
    }
    
    # Render the data table with specific options
    datatable(data_summary, options = list(
      pageLength = 5,    # ...number of entries per page
      lengthChange = TRUE, # ...enable ability to change the number of entries per page
      bFilter = 0        # ...disable the search/filter box
    ))
  })
  
  
  # The below prevents compareVar and dodgeVar from being set to identical 
  # values. If identical, it will switch dodgeVar to its default value of 
  # "nothing". This was done to avoid an unsightly error message in the app.
  
  
  # Reactive value to store the last selected value of compareVar
  last_compareVar <- reactiveVal()
  
  observe({
    # Update last_compareVar only if compareVar is not "nothing"
    if (input$compareVar != "nothing") {
      last_compareVar(input$compareVar)
    }
  })
  
  # ...observer for 'compareVar'
  observeEvent(input$compareVar, {
    if (input$compareVar == input$dodgeVar && input$compareVar != "nothing") {
      updateSelectInput(session, "dodgeVar", selected = "nothing")
    }
  }, ignoreInit = TRUE)
  
  # ...observer for 'dodgeVar'
  observeEvent(input$dodgeVar, {
    # Use the value stored in last_compareVar for comparison
    if (input$dodgeVar == last_compareVar() && input$dodgeVar != "nothing") {
      updateSelectInput(session, "dodgeVar", selected = "nothing")
    }
  }, ignoreInit = TRUE)
  
}


# -------------------------------- RUN APP ------------------------------------

# Running app based on flags


if("-i" %in% args) { # ...if -i flag is set, launch in IDE
  # ...some IDEs may not support this, in which case the app may launch in the browser.
  
  print("Trying to run app in the IDE...")
  print("Press Ctrl + C // Cmd + C when finished")
  
  shinyApp(ui, server)
  
} else { # ... if -i flag is not set, launch in browser
  
  print("Trying to run app in the browser...")
  print("If your app hasn't automatically launched, please copy and paste the local URL to your browser.")
  print("You can find the local URL in the below output. It may look something like http://127.0.0.1:xxxx")
  print("Press Ctrl + C // Cmd + C when finished")
  
  shinyApp(ui, server, options = list(
    launch.browser = TRUE # ...launch in browser (default)
  ))
}
# -----------------------------------------------------------------------------
#                               END OF SCRIPT