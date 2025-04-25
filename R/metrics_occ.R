#' metrics_occ
#'
#' Compute Metrics for Individual Predictions by Occasion
#'
#' This function calculates various prediction error metrics for individual pharmacokinetic simulations,
#' grouping results by occasion (OCC). It supports both `mapbayr` and `lixoftConnectors` tools.
#'
#' @param simulations A list containing simulation results from [run_ind_simulations()], must be used with tool `mapbayr`.
#' @param sims A list of simulation outputs from `lixoftConnectors`.
#' @param tool A character string specifying the tool used to obtain the list of simulations (`"mapbayr"` or `"lixoftConnectors"`).
#' @return A list with two elements:
#'   - `metrics`: A dataframe summarizing observation, individual prediction and error metrics for each ID in every OCC.
#'   - `metrics_means`: A dataframe containing the rBIAS, MAPE, rRMSE, IF20 AND IF30 .
#'
#' @examples
#' # Example usage with mapbayr
#' # results <- metrics_occ(simulations = my_simulations, tool = "mapbayr")
#' # Example usage with lixoftConnectors
#' # results <- metrics_occ(sims = my_sims, tool = "lixoftConnectors")
#'
#' @export
#'
metrics_occ <-
function(simulations,
                        sims,
                        tool = c("mapbayr", "lixoftconnectors"))  {
  if (tool == "mapbayr") {
  list.simulation = simulations[["simulation_results"]]
  combine= lapply(list.simulation, function(x) slot(x, "data"))
          df_simulaciones <- do.call(rbind, combine)
          df_simulaciones = df_simulaciones %>% rename(Ind_Prediction = DV) %>%
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
  else if (tool == "lixoftConnectors") {
    mm <- vector(mode='list', length = length(sims))
    mm[[1]] <- sims[[1]] %>%
      mutate(
        IPE = ((Cc- DV)/DV) *100,
        APE= abs(((Cc- DV)/DV))*100,
        RMSE = (((Cc-DV)^2)/((DV)^2))
      )

    mm[-1] <- lapply( sims[-1], metrics_occasion) ### Cambio menor que no estaba tomando bien los datos
    names(mm) <- names(sims)

    metrics <- bind_rows(mm)
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
