library(shiny)
library(shinyAce)

ui <- fluidPage(

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),

  navbarPage(
    title = tagList(
      img(src = "logo.png", height = "30px"),
      span(" preDose", style = "padding-left: 10px; font-weight: bold;")
    ),

    tabPanel(
      "Model & Data",
      sidebarLayout(
        sidebarPanel(
          class = "sidebar",

          fileInput("data_file", "Upload Patient Data (CSV)", accept = ".csv"),

          selectInput(
            "eval_type", "Evaluation Type",
            choices = c(
              "Progressive",
              "Most_Recent_Progressive",
              "Cronologic_Ref",
              "Most_Recent_Ref"
            )
          ),

          actionButton(
            "run_map",
            "Run MAP Estimations",
            class = "btn-primary btn-block"
          )
        ),

        mainPanel(
          h4("Model Code"),
          aceEditor(
            outputId = "model_code",
            value = "$Global\n\n$Prob\n- 2 Compartment model with Michaelis-Menten elimination\n\n$CMT @annotated\nEV   : Extravascular compartment (mg)\nCENT : Central compartment (mg)\nPERI : Peripheral (mg)\n",
            mode = "r",
            theme = "chrome",
            height = "400px",
            fontSize = 14
          )
        )
      )
    ),

    tabPanel(
      "MAP Estimations",
      plotOutput("map_plot")
    ),

    tabPanel(
      "Simulations",
      plotOutput("sim_plot")
    )
  )
)

erver <- function(input, output) {
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





ui <- fluidPage(

  tags$head(
    tags$link(rel = "stylesheet", href = "custom.css"),
    tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
    )
  ),

  h2("preDose Platform"),
  br(),

  fluidRow(

    column(
      4,
      div(
        class = "feature-card",
        icon("database", class = "feature-icon"),
        h4("Data Input"),
        p("Upload patient data, define models and prepare datasets.")
      )
    ),

    column(
      4,
      div(
        class = "feature-card",
        icon("chart-line", class = "feature-icon"),
        h4("External Evaluation"),
        p("Run external evaluations and assess model performance.")
      )
    ),

    column(
      4,
      div(
        class = "feature-card",
        icon("user-doctor", class = "feature-icon"),
        h4("Therapeutic Drug Monitoring"),
        p("Individual predictions, Bayesian forecasting and TDM.")
      )
    )
  )
)

server<- function(input, output)
