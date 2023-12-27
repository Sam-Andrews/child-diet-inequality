library(shinydashboard)
library(ggplot2)
library(dplyr)
library(shinyWidgets)
library(DT)
library(here)
library(shiny)


#shiny_df <- read.csv(here("../../clean", "clean_data.csv"))


shiny_df <- readRDS(here::here("../../clean", "data.rds"))

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


