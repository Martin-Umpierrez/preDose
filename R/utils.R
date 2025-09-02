individual_sim <-
function(posterior_model,
                           treatment,
                           start,
                           end,
                           ss_fixed = FALSE,
                           ss_n = NULL,
                           tad = FALSE) {

  posterior_model <- posterior_model %>%
    mrgsolve::data_set(treatment) %>%
    mrgsolve::update(start = start, end = end)

  sim_result <- mrgsolve::mrgsim(posterior_model)
  return(sim_result)
}

# dat <-
# function(file = "M2_TEST.mlxtran", occ = NULL){
#
#   lixoftConnectors::initializeLixoftConnectors(software = "monolix", force = TRUE)
#   lixoftConnectors::loadProject(projectFile = file)
#
#   occ_values <- protodata(filepath = file)[[2]]
#
#
#   lixoftConnectors::initializeLixoftConnectors(software = "simulx", force = TRUE)
#   lixoftConnectors::importProject(file)
#
#   tratamientos <- lixoftConnectors::getTreatmentElements()
#   filtered_treatments <- list()
#   for (occ_value in occ_values) {
#     tto_filtered <- tratamientos$mlx_Adm1$data %>%
#       filter(OCC == occ_value) %>%
#       select(-OCC, -washout)
#
#     df_name <- paste0("tto_", occ_value)
#     filtered_treatments[[df_name]] <- tto_filtered
#     file_name <- paste0("tto", occ_value, ".csv")
#     utils::write.csv(tto_filtered, file_name, row.names = FALSE)
#   }
#
#   Regresores <- lixoftConnectors::getRegressorElements()
#   reg_occ_list <- list()
#
#   for (occ_value in occ_values) {
#     reg_occ <- Regresores$mlx_Reg$data %>%
#       filter(OCC == occ_value)
#     df_name <- paste0("Reg_", occ_value)
#     reg_occ_list[[df_name]] <- reg_occ
#     csv_name <- paste0("Reg_", occ_value, ".csv")
#     utils::write.csv(reg_occ, file = csv_name, row.names = FALSE)
#   }
#
# }
# protodata <-
# function(filepath, occ = NULL, names_occ = 'OCC'){
#   lixoftConnectors::initializeLixoftConnectors(software = "monolix", force=TRUE)
#   lixoftConnectors::loadProject(projectFile = filepath)
#   out1 <- rio::import(lixoftConnectors::getData()$dataFile)
#   names(out1)[which(names(out1) == names_occ)] <- 'OCC'
#
#   if(is.null(occ)){
#     occ_values <- 2:max(out1$OCC)
#   }else{
#     occ_values <- 2:occ
#   }
#   return(list(out1 = out1, out2 = occ_values))
# }
# estimation_occ <-
# function(occ, datos, file){
#
#   Test_filter_OCC1 <-
#     datos %>%
#     filter(OCC <= occ)
#
#   utils::write.csv(Test_filter_OCC1, file = "Test_filter_OCC.csv", row.names = FALSE)
#   filtereddatfile <- "Test_filter_OCC.csv"
#
#   BaseData <- lixoftConnectors::getData()
#   lixoftConnectors::setData(filtereddatfile, BaseData$headerTypes, BaseData$observationTypes, BaseData$nbSSDoses)
#
#   new_estimation <- lixoftConnectors::runPopulationParameterEstimation()
#   lixoftConnectors::runConditionalModeEstimation()
#   IndividualParams <- lixoftConnectors::getEstimatedIndividualParameters()
#
#   # save predictions.txt, esto es la prediccion previa para contrastar con datos OCC=1
#   # guardar prediccion a priori, y levantarlo en la salida de simulation_mlp
#   # M2_TEST/predictions.txt
#   # id, DV, popPred, OCC
#   # popPred corresponde a la prediccion de cada dato (Cc)
#   if (occ == 1) {
#     #rr <- readLines( 'M2_TEST_ruta.mlxtran' )
#     rr <- readLines( file )
#     rrr <- gsub("'", "", rr[grep('exportpath', rr)] ) |>  strsplit(split = ' = ')
#
#     rio::import(paste0(rrr[[1]][2], '/predictions.txt')) |>
#       select(id, OCC, DV, popPred, time) |>
#       rename(Cc = popPred, ID = id) |>
#       write.csv('priorPred.csv', row.names = FALSE)
#   }
#
#   simparams_1 <-
#     IndividualParams[["conditionalMode"]] |>
#     filter(OCC == occ) |>
#     select(-OCC)
#
#   utils::write.csv(simparams_1,
#                    file = paste0("SIMPARAMS_TEST_OCC", occ, ".csv"),
#                    row.names = FALSE)
# }
# simulation_occ <-
# function(file = "M2_TEST.mlxtran", newD, o){
#   # initializeLixoftConnectors(software = "simulx", force=TRUE)
#   # importProject(file)
#   lixoftConnectors::deleteOccasionElement()
#   write.csv(newD, 'newD.csv', row.names = FALSE)
#
#   lixoftConnectors::defineOutputElement(name = 'Conc', element=list(data = 'newD.csv', output = "Cc"))
#   lixoftConnectors::defineIndividualElement(name = "Paramind", element= paste0("SIMPARAMS_TEST_OCC", o, ".csv") )
#   lixoftConnectors::defineTreatmentElement(name = "tto", element = list(data=paste0("tto", o+1, ".csv") ) )
#   lixoftConnectors::defineRegressorElement(name = "Reg", element = paste0("Reg_", o+1, ".csv") )
#
#   lixoftConnectors::setGroupElement(group = "simulationGroup1",
#                                     elements = c('Conc', "Reg", "tto", "Paramind"))
#
#   lixoftConnectors::setGroupSize(group = "simulationGroup1", size = length(unique(newD$ID)) )
#
#   lixoftConnectors::setSharedIds(sharedIds = c("individual","treatment","regressor"))
#   lixoftConnectors::runSimulation()
#   simresults <- lixoftConnectors::getSimulationResults()
#
#   return(simresults)
# }

metrics_occasion <-
function(simresults) {
  simresults$ID_mapping |>
    mutate(ID = as.numeric(ID), original_id_output = as.numeric(original_id_output)) |>
    right_join( simresults$res$Cc, by = join_by(ID == id)) |>
    select(-ID) |>
    # cbind(simresults$data) |>
    inner_join( simresults$data, by = join_by(original_id_output == ID, time) ) |>  # esta bien este merge?
    rename( ID = original_id_output ) |>
    select(ID, time, Cc, DV, OCC) |>
    mutate(DV = as.numeric(DV)) |>   # compute metrics
    mutate(
      IPE = ((Cc- DV)/DV) *100,
      APE= abs(((Cc- DV)/DV))*100,
      RMSE = (((Cc-DV)^2)/((DV)^2))
    )
  # OCC= first(OCC) ) # la ocacion tiene que venir de los datos!
}
verificar_OCC <-
function(modelo) {
  # Dividir el modelo en líneas
  lineas <- strsplit(modelo, "\n")[[1]]

  # Identificar el inicio de la sección $CAPTURE
  inicio_capture <- grep("^\\$CAPTURE", lineas)

  if (length(inicio_capture) == 0) {
    stop("Error: The $CAPTURE section was not found in the model.")
  }

  # Extraer todas las líneas desde $CAPTURE hasta el final del modelo
  seccion_capture <- lineas[inicio_capture:length(lineas)]

  # Verificar si 'OCC' está presente en la sección
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


