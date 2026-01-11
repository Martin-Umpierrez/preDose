library(shiny)
library(bslib)

ui <- page_navbar(theme = bs_theme(version = 5, bootswatch = "flatly"),


    # ===== HEADER / BRANDING =====
    title = div(
      style = "display: flex; align-items: center; gap: 15px;",

      tags$img(src = "predose.png", height = "35px"),
      tags$img(src = "udelar.png", height = "35px"),

      tags$span(
        "preDose",
        style = "font-weight: 600; font-size: 20px;"
      ),

      tags$span(
        "A Robust External Evaluation Package for PKPD models",
        class = "d-none d-md-inline",
        style = "font-size: 14px; color: #d1d5db;"
      )
    ),

    # ===== MAIN NAVIGATION (CONTENT) =====
    navset_tab(

      # ---------- DATA ----------
      nav_panel(
        title = "Data",

        layout_columns(
          col_widths = c(4, 8),

          card(
            card_header("Data upload"),
            fileInput("data_file", "Upload data (CSV)"),
            checkboxInput("header", "Header", TRUE)
          ),

          card(
            card_header("Data preview"),
            tableOutput("data_table")
          )
        )
      ),

      # ---------- EXTERNAL EVALUATION ----------
      nav_panel(
        title = "External evaluation",

        layout_columns(
          col_widths = c(4, 8),

          card(
            card_header("Model & settings"),
            selectInput("model_eval", "Model",
                        choices = c("Model 1", "Model 2")),
            actionButton("run_eval", "Run external evaluation")
          ),

          card(
            card_header("Evaluation results"),
            plotOutput("eval_plot"),
            hr(),
            tableOutput("eval_metrics")
          )
        )
      ),

      # ---------- TDM ----------
      nav_panel(
        title = "TDM",

        layout_columns(
          col_widths = c(4, 8),

          # INPUTS
          card(
            card_header("TDM workflow"),

            navset_card_tab(

              nav_panel(
                title = "Patient",
                numericInput("age", "Age (years)", 45),
                numericInput("weight", "Weight (kg)", 70),
                selectInput("sex", "Sex", c("Male", "Female"))
              ),

              nav_panel(
                title = "Information",
                selectInput("model_tdm", "PK model",
                            choices = c("Tacrolimus", "Cyclosporine")),
                numericInput("dose", "Dose (mg)", 5),
                numericInput("tau", "Dosing interval (h)", 12)
              ),

              nav_panel(
                title = "Laboratory",
                numericInput("conc", "Measured concentration", 7.5),
                numericInput("time", "Time post-dose (h)", 12),
                actionButton("run_tdm", "Run TDM")
              )
            )
          ),

          # OUTPUTS
          layout_columns(
            col_widths = c(6, 6),

            card(
              card_header("PK profile"),
              plotOutput("tdm_plot")
            ),

            card(
              card_header("Dose recommendation"),
              verbatimTextOutput("tdm_results")
            )
          )
        )
      )
    ),
    nav_spacer(),
    nav_menu(
      title = "Links",
      align = "right",
      nav_item(tags$a(icon("github"), " GitHub", href = "https://github.com/Martin-Umpierrez/preDose")),
      nav_item(tags$a("Cebiobe", href = "https://www.fq.edu.uy/?q=es/node/474")),
    )

  )


server <- function(input, output, session) {
  # server logic
}

shinyApp(ui, server)





ui <- page_navbar(
  title = "My App",
  bg = "#2D89C8",
  inverse = TRUE,
  nav_panel(title = "One", p("First page content.")),
  nav_panel(title = "Two", p("Second page content.")),
  nav_panel(title = "Three", p("Third page content.")),
  nav_spacer(),
  nav_menu(
    title = "Links",
    align = "right",
    nav_item(tags$a("Posit", href = "https://posit.co")),
    nav_item(tags$a("Shiny", href = "https://shiny.posit.co"))
  )
)



