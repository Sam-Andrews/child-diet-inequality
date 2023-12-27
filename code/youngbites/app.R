# Run required libraries

renv::restore() # ...restore packages from renv lock file

library(shinydashboard)
library(ggplot2)
library(dplyr)
library(shinyWidgets)
library(DT)
library(here)
library(shiny)


# Set colours for plotting

col_1 <- "#F4B860"
col_2 <- "#388697"
col_3 <- "#DB7F8E"
col_4 <- "#9DBF9E"
col_5 <- "#7A9D96"
col_6 <- "#B0A8B9"
col_7 <- "#808F4D"
col_8 <- "#E97451"
col_9 <- "#A0DAA9"
col_10 <- "#673147"

color_palette <- c(col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8,
                   col_9, col_10)



# Read data frame

shiny_df <- readRDS(here::here("../clean", "data.rds"))

# --------------------------------- UI ---------------------------------------

ui <- dashboardPage(
  
  ## Header
  
  dashboardHeader(title = "Young Bites App"),
  
  ## Theme
  
  skin = "blue",
  
  
  ## Sidebar
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
    
    selectInput("compareVar", "changes by...", choices = names(shiny_df)),
    
    selectInput("dodgeVar", "and compares across...", 
                choices = c(
                  "nothing" = "nothing",
                  "gender" = "gender",
                  "ethnicity" = "ethnicity",
                  "age" = "age"
                ), selected = "nothing"),
    
    tags$h5("Colourblind mode", class = "text-center"), # ...(custom HTML)
    
    # Wrap the switchInput in a div to center it
    div(
      switchInput(
        inputId = "Id018",
        label = "<i class=\"fa fa-thumbs-up\"></i>"
      ),
      style = "text-align: center;"  # This will center the switch
    )
  ),
  
  
  ## Main body
  
  dashboardBody(
    
    fluidRow(
      
      # # 'Number of observations' box
      # valueBoxOutput("nBox"),
      
      # Average fruit index box
      valueBoxOutput("fruitBox"),
      
      # Average veg index box
      valueBoxOutput("vegBox"),
      
      # Average sugar index box
      valueBoxOutput("sugarBox"),
      
      
      # Plot box
      box(title = "Chart", status = "primary", solidHeader = FALSE, 
          plotOutput("plot1", height = 250), width = 6),
      
      # Data table box
      box(title = "Data table", status = "warning", solidHeader = FALSE,
          DTOutput("dataTable"), width = 6), 
      
      # Information box for variables
      tabBox(
        title = "Variable guide",
        # The id lets us use input$tabset1 on the server to find the current tab
        id = "tabset1", height = "250px",
        # Use HTML for text formatting
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
     any high-sugar product at least 5-6 times per week."))
      )
    ),
  ),
)




# ----------------------------- SERVER LOGIC ---------------------------------


server <- function(input, output, session) {

  
  # Data box 1: Average fruit index  
  
  output$fruitBox <- renderValueBox({
    # Calculate the average fruit index
    avg_fruit <- round(mean(shiny_df$`the fruit index`), digits = 2)
    valueBox(
      avg_fruit, "...average fruit index", icon = icon("fa-sharp fa-solid fa-lemon", lib = "font-awesome"),
      color = "yellow"
    )
  })
  
  
  # Data box 2: Average veg index  
  
  output$vegBox <- renderValueBox({
    # Calculate the average fruit index
    avg_veg <- round(mean(shiny_df$`the vegetable index`), digits = 2)
    valueBox(
      avg_veg, "...average vegetable index", icon = icon("fa-sharp fa-solid fa-carrot", lib = "font-awesome"),
      color = "red"
    )
  })
  
  
  # Data box 3: Average sugar index  
  
  output$sugarBox <- renderValueBox({
    # Calculate the average fruit index
    avg_sugar <- round(mean(shiny_df$`the sugar index`), digits = 2)
    valueBox(
      avg_sugar, "...average sugar index", icon = icon("fa-sharp fa-solid fa-cubes-stacked", lib = "font-awesome"),
      color = "purple"
    )
  })
  
  
  
  # Plot
  output$plot1 <- renderPlot({
    req(input$outcomeVar, input$compareVar)
    
    data <- shiny_df
    
    # Define compareVar and dodgeVar outside the if-else to make them available in the entire scope
    compareVar <- paste0("`", input$compareVar, "`")
    dodgeVar <- if(!is.null(input$dodgeVar) && input$dodgeVar != "nothing") paste0("`", input$dodgeVar, "`") else NULL
    
    # Determine the variable to use for filling
    fillVar <- if(dodgeVar == "nothing" || is.null(dodgeVar)) compareVar else dodgeVar
    
    # Check if the outcome variable is a factor
    if(is.factor(data[[input$outcomeVar]])) {
      # Group by compareVar and by dodgeVar (if dodgeVar is specified)
      group_vars <- rlang::syms(c(input$compareVar, if (!is.null(dodgeVar)) input$dodgeVar))
      data <- data %>%
        dplyr::group_by(!!!group_vars) %>%
        dplyr::summarise(YesProportion = mean(as.numeric(.data[[input$outcomeVar]] == "Yes"), na.rm = TRUE))
      
      # Initialise the plot object for factor outcomeVar
      p <- ggplot(data, aes_string(x = compareVar, y = "YesProportion", fill = fillVar)) +
        scale_fill_manual(values = color_palette)
      
      # Modify the plot for factor outcomeVar
      p <- p +
        geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
        scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
        labs(y = "Proportion of 'Yes'", x = input$compareVar) +
        theme_bw()
    } else {
      # For continuous outcomeVar, proceed with the original plotting method
      outcomeVar <- paste0("`", input$outcomeVar, "`")
      
      # Initialise the plot object for continuous outcomeVar
      p <- ggplot(data, aes_string(x = compareVar, y = outcomeVar, fill = fillVar)) +
        scale_fill_manual(values = color_palette)
      
      # For continuous outcomeVar, display the average mean
      p <- p + 
        geom_bar(stat = "summary", fun.y = "mean", position = position_dodge(width = 0.9)) +
        labs(y = "Average Mean", x = input$compareVar) +
        theme_bw()
    }
    
    # Print plot object
    print(p)
  })
  
  
  
  
  
  # Data table
  # Data table should mirror the server logic of the 'plot'
  
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
      lengthChange = TRUE,
      bFilter = 0
    ))
  })
  
  
# The below prevents compareVar and dodgeVar from being set to identical 
# values. If identical, it will switch dodgeVar to its default value of 
# ("nothing").
  

  # Reactive value to store the last selected value of compareVar that is not "nothing"
  last_compareVar <- reactiveVal()
  
  observe({
    # Update last_compareVar only if compareVar is not "nothing"
    if (input$compareVar != "nothing") {
      last_compareVar(input$compareVar)
    }
  })
  
  # Observer for 'compareVar'
  observeEvent(input$compareVar, {
    if (input$compareVar == input$dodgeVar && input$compareVar != "nothing") {
      updateSelectInput(session, "dodgeVar", selected = "nothing")
    }
  }, ignoreInit = TRUE)
  
  # Observer for 'dodgeVar'
  observeEvent(input$dodgeVar, {
    # Use the value stored in last_compareVar for comparison
    if (input$dodgeVar == last_compareVar() && input$dodgeVar != "nothing") {
      updateSelectInput(session, "dodgeVar", selected = "nothing")
    }
  }, ignoreInit = TRUE)
  
}


shinyApp(ui, server, options = list(launch.browser = TRUE))
