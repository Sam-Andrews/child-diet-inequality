# Source activate.R as a failsafe (should it not automatically run)

# ...define the path using the 'here' package
sourcepath <- here("renv", "activate.R")

# ...check if activate.R exists and source it
if (file.exists(sourcepath)) {
  source(sourcepath)
} else {
  stop("activate.R file not found. Please ensure it exists at ", sourcepath)
}


# Run required libraries

renv::restore() # ...restore packages from renv.lock

library(shinydashboard)
library(ggplot2)
library(dplyr)
library(shinyWidgets)
library(DT)
library(here)
library(shiny)

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
col_9 <- "#A0DAA9"
col_10 <- "#363537"

colour_palette <- c(col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8,
                   col_9, col_10)

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
  ## ...these elements control the data subsetting
  dashboardSidebar(
    
    selectInput("outcomeVar", "I want to see how...", 
                choices = c(
                  "the fruit index",
                  "the vegetable index",
                  "the sugar index",
                  "low fruit consumption",
                  "low vegetable consumption",
                  "high sugar consumption"
                )),
    
    selectInput("compareVar", "changes by...", 
                choices = c(
                  "gender",
                  "ethnicity",
                  "age",
                  "annual household income",
                  "size of household"
                )),
    
    selectInput("dodgeVar", "and compares across...", 
                choices = c(
                  "nothing",
                  "gender",
                  "ethnicity",
                  "age",
                  "annual household income",
                  "size of household"
                ), selected = "nothing"),
    
    ## Adding a colour-blindness mode toggle
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
  
  
  ## Main body
  
  dashboardBody(
    
    fluidRow(
      
      # Average fruit index box
      valueBoxOutput("fruitBox"),
      
      # Average veg index box
      valueBoxOutput("vegBox"),
      
      # Average sugar index box
      valueBoxOutput("sugarBox"),
      
      
      # Plot box
      box(title = "Chart", status = "primary", solidHeader = FALSE, 
          plotOutput("plot1", height = 400), width = 6),
      
      # Data table box
      box(title = "Data table", status = "warning", solidHeader = FALSE,
          DTOutput("dataTable"), width = 6), 

      
      # Information box for variables
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
                    HTML("'Extreme consumption groups' were constructed slightly differently between
     fruit/veg and sugar.
     <br>
     <br>
     For fruit and veg, a child is counted as part of the 'low consumption 
     group' if they consume fruit/veg just once per month or less often.
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
      <em>unhealthy eaters</em>, their score could average out somewhere down the 
      middle.
      <br>
      <br>
      On the other hand, 'extreme consumption' variables are geared towards
      identifying vulnerable demographics, but do not tell us anything about
      the frequency of <em>healthy</em> consumption within these groups. 
      Therefore, it's important not to generalise what these variables tell us 
      about particular demographics."))
      ),
      
      # Download plot button - possibly won't implement
      #downloadButton("downloadPlot", "Download Plot"),
      
    ),
  ),
)




# ----------------------------- SERVER LOGIC ---------------------------------


server <- function(input, output, session) {

  
  # Data box 1: Average fruit index  
  
  output$fruitBox <- renderValueBox({
    # Calculate the average fruit index
    avg_fruit <- round(mean(shiny_df$`the fruit index`, na.rm = TRUE), digits = 2)
    valueBox(
      avg_fruit, "...average fruit index", icon = icon("fa-sharp fa-solid fa-lemon", lib = "font-awesome"),
      color = # ...color argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "yellow"
        } else {"olive"}
    )
  })
  
  
  # Data box 2: Average veg index  
  
  output$vegBox <- renderValueBox({
    # Calculate the average veg index
    avg_veg <- round(mean(shiny_df$`the vegetable index`, na.rm = TRUE), digits = 2)
    valueBox(
      avg_veg, "...average vegetable index", icon = icon("fa-sharp fa-solid fa-carrot", lib = "font-awesome"),
        color = # ...color argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "red"
        } else {"aqua"}
    
    )
  })
  
  
  # Data box 3: Average sugar index  
  
  output$sugarBox <- renderValueBox({
    # Calculate the average sugar index
    avg_sugar <- round(mean(shiny_df$`the sugar index`, na.rm = TRUE), digits = 2)
    valueBox(
      avg_sugar, "...average sugar index", icon = icon("fa-sharp fa-solid fa-cubes-stacked", lib = "font-awesome"),
      color = # ...color argument depends on colourblindness setting
        if(input$Id018 != TRUE) {
          "purple"
        } else {"maroon"}
    
    )
  })
  
  
  
  # Plot
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
    } else {
      # For continuous outcomeVar, proceed with the original plotting method
      outcomeVar <- paste0("`", input$outcomeVar, "`")
      
      # Initialise the plot object for continuous outcomeVar
      p <- ggplot(data, aes_string(x = compareVar, y = outcomeVar, fill = fillVar)) +
        if(input$Id018 == TRUE) {
          scale_fill_manual(values = cb_colour_palette)
        } else {
          scale_fill_manual(values = colour_palette)
        }
      
      # For continuous outcomeVar, display the mean for the index
      p <- p + 
        geom_bar(stat = "summary", fun.y = "mean", position = position_dodge(width = 0.9)) +
        labs(y = "Mean Index Score", x = input$compareVar) +
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
    compareVar <- paste0("`", input$compareVar, "`")
    dodgeVar <- if(!is.null(input$dodgeVar) && input$dodgeVar != "nothing") paste0("`", input$dodgeVar, "`") else NULL
    
    if(is.factor(data[[input$outcomeVar]])) {
      group_vars <- rlang::syms(c(input$compareVar, if (!is.null(dodgeVar)) input$dodgeVar))
      data_summary <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(`Proportion (%)` = round(100 * mean(as.numeric(.data[[input$outcomeVar]] == "Yes"), na.rm = TRUE), 1),
                         Count = n(),
                         .groups = 'drop')
    } else {
      outcomeVar <- paste0("`", input$outcomeVar, "`")
      group_vars <- rlang::syms(c(input$compareVar, if (!is.null(dodgeVar)) input$dodgeVar))
      data_summary <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(Mean = round(mean(.data[[input$outcomeVar]], na.rm = TRUE), 1),
                         Count = n(),
                         .groups = 'drop')
    }
    
    datatable(data_summary, options = list(
      pageLength = 5,
      lengthChange = FALSE,
      bFilter = 0
    ))
  })
  

  
  # The below prevents compareVar and dodgeVar from being set to identical 
  # values. If identical, it will switch dodgeVar to its default value of 
  # "nothing". This was done to avoid an unsightly error message in the app.


  # Reactive value to store the last selected value of compareVar that is not "nothing"
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


# ------------------------------- RUN APP -------------------------------------

# Running app based on flags


if("-i" %in% args) {
  
  print("Trying to run app in the GUI...")
  print("Press Ctrl + C // Cmd + C when finished")
  
  print(shinyApp(ui, server, options = list(
    launch.browser = FALSE # ...enable GUI launch
  )))
  
} else {
  
  print("Trying to run app in the browser...")
  print("If your app hasn't automatically launched, please copy and paste the local URL to your browser.")
  print("You can find the local URL in the below output. It may look something like http://127.0.0.1:1234")
  print("Press Ctrl + C // Cmd + C when finished")
  
  shinyApp(ui, server, options = list(
    launch.browser = TRUE # ...force browser launch instead of GUI window
  ))
}
