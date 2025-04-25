ui <- fluidPage(
  titlePanel("Tacrolimus PK Model"),
  sidebarLayout(
    sidebarPanel(
      fileInput("data_file", "Upload Patient Data (CSV)", accept = ".csv"),
      selectInput("eval_type", "Evaluation Type",
                  choices = c("Progressive", "Most_Recent_Progressive", "Cronologic_Ref", "Most_Recent_Ref")),
      actionButton("run_map", "Run MAP Estimations")
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
