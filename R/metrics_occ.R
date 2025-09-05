#' metrics_occ
#'
#' Compute Metrics for Individual Predictions by Occasion
#'
#' This function calculates various prediction error metrics for individual pharmacokinetic simulations,
#' grouping results by occasion (OCC). Currently supports  `mapbayr` models.
#'
#' @param simulations A list containing simulation results from [run_ind_simulations()].
#' @param assessment Character string. Specifies the type of prediction to perform. Options are:
#'   \itemize{
#'     \item "a_priori": Simulates concentrations using the population model without individual data.
#'     \item "Bayesian_Forecasting": Simulates concentrations using individual parameter estimates (posterior mode).
#'     \item "Complete": Performs both a priori and Bayesian forecasting simulations.
#'   }
#' @param tool A character string specifying the tool used to obtain the list of simulations (`"mapbayr"` or `"lixoftConnectors"`).
#' @return A list with two elements:
#'   - `metrics`: A dataframe summarizing observation, individual prediction and error metrics for each ID in every OCC.
#'   - `metrics_means`: A dataframe containing the rBIAS, MAPE, rRMSE, IF20 AND IF30 .
#'
#' @examples
#' # results <- metrics_occ(simulations = my_simulations, assessment="Complete)
#'
#' @export
#'
metrics_occ <- function(simulations,
                       assessment = c("a_priori",
                                      "Bayesian_forecasting",
                                      "Complete"),
                       tool = "mapbayr")  {

  # Robust asignment of arguments
  assessment <- match.arg(assessment)
  tool <- match.arg(tool)

  # MAPbayr + B.Forecasting
  if (tool == "mapbayr"  && assessment== "Bayesian_forecasting" ) {
    list.simulation<- simulations[["simulation_results"]]
    combine <- lapply(list.simulation, function(x) slot(x, "data"))
    df_simulaciones <- do.call(rbind, combine)
    df_simulaciones <- df_simulaciones %>% rename(Ind_Prediction = DV) %>%
      select (ID, OCC, TIME, Ind_Prediction) %>% filter(Ind_Prediction>0)


    listtratamientos <- simulations[["ttoocc"]]
    df_ttos <- do.call(rbind,listtratamientos) %>% filter(EVID==0) %>%
      select(ID, OCC, TIME, DV)

    df_merged = left_join(df_simulaciones, df_ttos, by=c("ID", "OCC","TIME"))
    metrics = df_merged %>% mutate(
      IPE = ((Ind_Prediction- DV)/DV) *100,
      APE= abs(((Ind_Prediction-DV)/DV))*100,
      RMSE = (((Ind_Prediction-DV)^2)/((DV)^2))
    ) %>% filter(!is.na(DV)) %>% distinct()

  }

  # MAPbayr + "apriori"
  else if (tool == "mapbayr"  && assessment== "a_priori" ) {
    list.simulation = simulations[["simulation_results"]]
    combine= lapply(list.simulation, function(x) slot(x, "data"))
    df_simulaciones <- do.call(rbind, combine)
    df_simulaciones = df_simulaciones %>% rename(Ind_Prediction = CP) %>%
      select (ID, OCC, TIME, Ind_Prediction) %>% filter(Ind_Prediction>0)

    listtratamientos = simulations[["ttoocc"]]
    df_ttos = do.call(rbind, listtratamientos) %>% filter(EVID==0) %>%
      select(ID, OCC, TIME, DV)

    df_merged = left_join(df_simulaciones, df_ttos, by=c("ID", "OCC","TIME"))

    metrics = df_merged %>% mutate(
      IPE = ((Ind_Prediction- DV)/DV) *100,
      APE= abs(((Ind_Prediction-DV)/DV))*100,
      RMSE = (((Ind_Prediction-DV)^2)/((DV)^2))
    ) %>% filter(!is.na(DV)) %>% distinct()
  }

  # MAPbayr + "Complete": "a priori" + Bayesian Forecasting
  else if (tool == "mapbayr" && assessment == "Complete") {
    list.simulation <- simulations[["simulation_results"]]
    combine <- lapply(list.simulation, function(x) slot(x, "data"))
    df_simulaciones <- do.call(rbind, combine)

    # rename predictions 
    df_simulaciones <- df_simulaciones %>%
      mutate(Ind_Prediction = ifelse(OCC == 1, CP, DV)) %>%  # CP para apriori (OCC1), DV para posteriores
      select(ID, OCC, TIME, Ind_Prediction) %>%
      filter(Ind_Prediction > 0)

    # get tto for every OCC
    listtratamientos <- simulations[["ttoocc"]]
    df_ttos <- do.call(rbind, listtratamientos) %>%
      filter(EVID == 0) %>%
      select(ID, OCC, TIME, DV)


    df_merged <- left_join(df_simulaciones, df_ttos, by = c("ID", "OCC", "TIME"))

    metrics <- df_merged %>%
      mutate(
        IPE = ((Ind_Prediction - DV) / DV) * 100,
        APE = abs((Ind_Prediction - DV) / DV) * 100,
        RMSE = ((Ind_Prediction - DV)^2) / ((DV)^2)
      ) %>%
      filter(!is.na(DV)) %>%
      distinct()
  }

  if (!exists("metrics") || nrow(metrics) == 0) {
    stop("The 'metrics' object could not be generated. Please check the data and arguments.")
  }

  metrics_means <- metrics %>%
    group_by(OCC) %>%
    summarise(
      rBIAS= mean(IPE),
      rBIAS_lower = mean(IPE)-( qt(0.975, df = length(IPE) - 1) *(sd(IPE) / sqrt(length(IPE)))),
      rBIAS_upper = mean(IPE) +( qt(0.975, df = length(IPE) - 1) *(sd(IPE) / sqrt(length(IPE)))),
      MAIPE= mean(APE),
      rRMSE= sqrt(mean(RMSE)) *100,
      IF20= sum(abs(IPE) <= 20) *100 / length(IPE),
      IF30= sum(abs(IPE) <= 30) *100 / length(IPE),
      OCC= first(OCC) )

  out <- list(metrics=metrics, metrics_means = metrics_means)
  return(out)
}
