library(shiny)
library(shinydashboard)
library(shinyAce)
ui <- fluidPage(
  titlePanel("preDose: A Robust External Evaluation Package forPKPD models"),
  sidebarLayout(
    sidebarPanel(
      fileInput("data_file", "Upload Patient Data (CSV)", accept = ".csv"),

      selectInput("eval_type", "External Evaluation Type",
                  choices = c("Progressive",
                              "Most_Recent_Progressive",
                              "Cronologic_Ref",
                              "Most_Recent_Ref")),
      actionButton("run_map", "Run MAP Estimations"),
      aceEditor(
        outputId = "model_code",
        value = "$Global\n\n$Prob\n- 2 Compartment model with Michaelis-Menten elimination\n\n$CMT @annotated\nEV   : Extravascular compartment (mg)\nCENT : Central compartment (mg)\nPERI : Peripheral (mg)\n",
        mode = "r",
        theme = "chrome",
        height = "400px",
        fontSize = 14,
        showPrintMargin = FALSE,
        highlightActiveLine = TRUE
      )


    ),
    mainPanel(
      tabsetPanel(
        tabPanel("MAP Estimations", plotOutput("map_plot")),
        tabPanel("Updated Model", plotOutput("updated_plot")),
        tabPanel("Simulations", plotOutput("sim_plot"))
      )
    )
  )
)

server <- function(input, output) {
  data <- reactive({
    req(input$data_file)
    read.csv(input$data_file$datapath)
  })

  map_results <- eventReactive(input$run_map, {
    req(data())
    run_MAP_estimations(model_name = "Tacrolimus Model", model_code = "...",
                        tool = "mapbayr", data = data(), evaluation_type = input$eval_type)
  })

  output$map_plot <- renderPlot({
    req(map_results())
    ggplot(data(), aes(x = TIME, y = DV)) +
      geom_point() +
      labs(title = "MAP Estimations")
  })
}

shinyApp(ui, server)
