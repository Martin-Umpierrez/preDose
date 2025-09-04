individual_sim <-
function(posterior_model, treatment, start,
         end, ss_fixed = FALSE, ss_n = NULL, tad = FALSE) {

  posterior_model <- posterior_model %>%
    mrgsolve::data_set(treatment) %>%
    mrgsolve::update(start = start, end = end)

  sim_result <- mrgsolve::mrgsim(posterior_model)
  return(sim_result)
}

metrics_occasion <-
function(simresults) {
  simresults$ID_mapping |>
    dplyr::mutate(ID = as.numeric(ID), original_id_output = as.numeric(original_id_output)) |>
    dplyr::right_join( simresults$res$Cc, by = join_by(ID == id)) |>
    dplyr::select(-ID) |>
    # cbind(simresults$data) |>
    dplyr::inner_join( simresults$data, by = join_by(original_id_output == ID, time) ) |>
    dplyr::rename( ID = original_id_output ) |>
    dplyr::select(ID, time, Cc, DV, OCC) |>
    dplyr::mutate(DV = as.numeric(DV)) |>   # compute metrics
    dplyr::mutate(
      IPE = ((Cc- DV)/DV) *100,
      APE= abs(((Cc- DV)/DV))*100,
      RMSE = (((Cc-DV)^2)/((DV)^2))
    )
}
verificar_OCC <- function(modelo) {
  # split every line of the model code
  lineas <- strsplit(modelo, "\n")[[1]]

  # starts of $CAPTURE
  inicio_capture <- grep("^\\$CAPTURE", lineas)

  if (length(inicio_capture) == 0) {
    stop("Error: The $CAPTURE section was not found in the model.")
  }

  # lines from $CAPTURE to the end
  seccion_capture <- lineas[inicio_capture:length(lineas)]

  # Use word boundaries to ensure 'OCC' is matched as a whole word
  if (any(grepl("\\bOCC\\b", seccion_capture))) {
    message("Validation successful: 'OCC' is present in the $CAPTURE section.")
    return(TRUE)
  } else {
    stop("Error: 'OCC' is not present in the $CAPTURE section.")
  }
}


pop_sim <-
  function(population_model,
           treatment,
           start,
           end,
           ss_fixed = FALSE,
           ss_n = NULL,
           tad = FALSE) {

    population_model <- posterior_model %>%
      mrgsolve::data_set(treatment) %>%
      mrgsolve::update(start = start, end = end)

    sim_result <- mrgsolve::mrgsim(posterior_model)
    return(sim_result)
  }


