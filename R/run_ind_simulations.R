#' Run Individual Simulations
#'
#' Simulates individual concentrations based on posterior estimations and treatment schedules for each occasion.
#'
#' @param individual_model A list object generated from the `actualize_model` function. It contains posterior estimations for every ID on each occasion.
#' @param tto_occ A list object generated from the `run_map_estimations` function. It contains treatment schedules for every ID in each occasion.
#'
#' @return A list containing:
#' \item{simulation_results}{A list of simulation results for each occasion and individual.}
#' \item{ttoocc}{A list of treatments organized by occasion.}
#' \item{events_tto}{A list of treatment events for each occasion.}
#'
#' @details This function performs individual simulations for multiple occasions and individuals at the times an observation is available.
#' For each posterior estimation, it retrieves the corresponding treatment schedule and executes a simulation
#' over the specified time range. The results are stored for each individual within each occasion.
#'
#' @examples
#' # Assuming `individual_model` is created with actualize_model
#' # and `tto_occ` is created with run_map_estimations:
#'
#' results <- run_ind_simulations(individual_model, tto_occ)
#'
#' # Access simulation results
#' sim_results <- results$simulation_results
#'
#' # Access treatment by occasion
#' treatments <- results$ttoocc
#'
#' # Access treatment events
#' events <- results$events_tto
#'
#' @seealso \code{\link{actualize_model}}, \code{\link{run_map_estimations}}
#'
#' @export

run_ind_simulations <-
function(individual_model, tto_occ) {
    # Use el objeto generado en actulize model, tto_occ use el objeto generado en run map estimations

    simulation_results <- list()
    event.tto <- list()
    treatment.occ.list <- list()

    # Generalizar la lista de estimaciones a posteriori
    posterior_estimations <- individual_model$ind_model
    tto_by_occ <- tto_occ$treatments_by_occ

    # El loop grande recorre las estimaciones a posteriori de todos
    for (occasion_name in names(posterior_estimations)) {
      occ_posterior <- posterior_estimations[[occasion_name]]
      occ_number <- sub(".*_", "", occasion_name) # Extraer el número de la ocasión

      event.tto.byocc <- list()
      tto.occ.names <- paste0("OCC", occ_number) # Guardar los tratamientos

      treatment.occ.list[[tto.occ.names]] <- tto_by_occ[[paste0("tto_", occ_number)]]

      for (id_identifyer in names(occ_posterior)) {
        id_posterior <- occ_posterior[[id_identifyer]] # Modelo a posteriori para cada ID
        id_number <- sub("ID_", "", id_identifyer) # Extraer el número del individuo

        # Manejo de errores con tryCatch
        tryCatch({
          # Obtener los tratamientos para cada ID en cada ocasión
          treatment <- tto_by_occ[[paste0("tto_occ_", occ_number)]][[paste0("ev.tto.occ", occ_number, "_ID", id_number)]]

          # Determinar los tiempos de inicio y fin
          start <- min(treatment$TIME)
          end <- max(treatment$TIME)

          # Ejecutar la simulación individual
          sim_results <- individual_sim(id_posterior, treatment, start, end)

          # Agrego para que se obtengan solo datos de esa OCC esto pasa cuando simulo todas las OCC(no ss)
          sim_results@data <- subset(sim_results@data, OCC == occ_number)

          # Guardar los resultados de la simulación
          simulation_results[[paste0("OCC_", occ_number, "_ID", id_number)]] <- sim_results
          event.tto.byocc[[paste0("ID_", id_number)]] <- treatment

        }, error = function(e) {
          # Manejar el error mostrando un mensaje
          message(paste0("Could not process OCC_", occ_number, " ID_", id_number, " there is no treatment for ID in this Occasion:", e$message))
        })
      }

      # Guardar eventos de tratamiento por ocasión
      event.tto[[paste0("OCC_", occ_number)]] <- event.tto.byocc
    }

    # Retornar los resultados como una lista
    return(list(
      simulation_results = simulation_results,
      ttoocc = treatment.occ.list,
      events_tto = event.tto
    ))
  }
