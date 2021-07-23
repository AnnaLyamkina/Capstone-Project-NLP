#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)

# Application for typing help
shinyUI(fluidPage(
    
    # Application title
    titlePanel("Typing help"),
    sidebarLayout(
        sidebarPanel(
            tabsetPanel(type = "tabs",
                tabPanel("App", 
                        br(),
                        p("Insert yout tex in the top field."),
                        p("Below you will find the top candidate words provided by the model."),
                        p("Click on a word to add it to the input text."),
                        strong("Enjoy!")),
                tabPanel("Model", 
                         br(),
                         p("We analyze last", span("three", style = "font-style: italic"), "words from the input and apply a simple model:"),
                         tags$ol(tags$li("look for an exact match in fourgrams"),
                         tags$li("look for an exact match in trigrams"),
                         tags$li("look for a soft match (words 1 and 3 or 1 and 2) in fourgrams.
                         Get unique, sort by frequency."),
                         tags$li("look for a match in bigrams."),
                         tags$li("if not enough, add three most popular single words"))),
                tabPanel("Info",
                         p("Documentation can be found ", a("here", href = "https://rpubs.com/annalyamkina/792929", .noWS = "outside"), "."),
                         br(),
                         p("Code can be found ", a("here", href = "", .noWS = "outside"), "."))
            ),
            width = 4
        ),
        mainPanel(
            textInput('inputtext', 'Enter your text', value = "Hello fellow student! Have a good ", placeholder = "your text", width = "100%"),
            #p("Last three words:"),
            #textOutput('last_words'),
            p("Click to select from the top candidate words:"),
            DT::dataTableOutput("candidates")
        )

        
    )
    
))
