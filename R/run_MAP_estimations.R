#' Run MAP Estimations
#'
#' Performs Maximum A Posteriori (MAP) estimations for pharmacokinetic models
#' using either `mapbayr` or `lixoftConnectors`.
#'
#' @param model_name Character string. Name of the model to use in the analysis.
#' @param model_code Character string. Code of the pharmacokinetic model in mrgsolve format.
#' @param tool Character string. Specifies the tool to use for estimation. Options are "mapbayr" or "lixoftconnectors".
#' @param check_compile Logical. If `TRUE`, checks if the model compiles correctly in `mapbayr`.
#' @param data Data frame. Contains the input data for the estimations, including columns like ID, TIME, and OCC.
#' @param num_occ Integer. Number of occasions (OCC) to include in the analysis. If `NULL`, all unique occasions in `data` are used.
#' @param num_ids Integer. Number of unique IDs to include in the analysis. If `NULL`, all IDs are included.
#' @param sampling Logical. If `TRUE`, randomly samples the specified number of IDs from the data.
#' @param occ_ref Integer. Reference occasion for evaluation types that require a reference. Must be consistent with `evaluation_type`.
#' @param evaluation_type Character string. Specifies the evaluation type. Options are:
#'   \itemize{
#'     \item "Progressive": Uses all data up to each occasion.
#'     \item "Most_Recent_Progressive": Uses only the most recent occasion.
#'     \item "Cronologic_Ref": Uses all data up to a reference occasion.
#'     \item "Most_Recent_Ref": Uses the most recent occasion relative to a reference.
#'   }
#' @param file_mlxtran Character string. Path to the `.mlxtran` file for `lixoftConnectors`.
#' @param names_occ Character string. Name of the OCC column in the data. Defaults to "OCC".
#' @param names_id Character string. Name of the ID column in the data. Defaults to "ID".
#' @param names_time Character string. Name of the TIME column in the data. Defaults to "TIME".
#' @param names_evid Character string. Name of the EVID column in the data. Defaults to "EVID".
#' @param method Character vector. Specifies optimization methods for `mapbayr`. Options are "L-BFGS-B" or "newuoa".
#'
#' @return A list containing:
#' \describe{
#'   \item{data_by_occ}{Filtered datasets by occasion.}
#'   \item{treatments_by_occ}{List of treatments grouped by occasion.}
#'   \item{treatments_apriori}{List of "a priori" treatments }
#'   \item{map_estimations}{MAP estimation results for each subset of the data.}
#'   \item{eval_type}{The evaluation type used.}
#'   \item{pop_model}{The population PK or PKPD model}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' # Example using mapbayr
#' run_MAP_estimations(
#'   model_name = "example_model",
#'   model_code = "example_code",
#'   tool = "mapbayr",
#'   data = example_data,
#'   evaluation_type = "Progressive"
#' )
#' }

run_MAP_estimations <-
function(model_name, model_code,
                                tool = c("mapbayr", "lixoftconnectors"),### From mrg mode
                                check_compile = TRUE,
                                data, num_occ = NULL, ### Para lixoft definimos solo occ
                                num_ids= NULL,
                                sampling = TRUE,
                                occ_ref = NULL , ### Se usa solo si evaluation_type es basado en una referencia
                                evaluation_type = c("Progressive", "Most_Recent_Progressive",
                                                    "Cronologic_Ref","Most_Recent_Ref"), ## Como se va a hacer la eval externa
                                file_mlxtran= "M2_TEST.mlxtran",
                                names_occ = "OCC",
                                names_id = "ID",
                                names_time = "TIME",
                                names_evid = "EVID",
                                method = c("L-BFGS-B", "newuoa")) {
  # Verificar  base de datos e inputs, seleccion de errores
  if (!is.null(occ_ref) && !is.null(num_occ) && occ_ref != num_occ) {
    stop("occ_ref and num_occ must have the same value if both are specified.")
  }

  if (!is.null(occ_ref) && !is.null(num_occ) && occ_ref != num_occ) {
    stop("occ_ref and num_occ must have the same value if both are specified.")
  }

  if (!is.null(occ_ref) && (evaluation_type =="Progressive" || evaluation_type ==
                            "Most_Recent_Progressive")) {
    stop("occ_ref must be used wwith evaluation type Cronologic_Ref or Most_Recent_Ref")
  }

  if (tool == "mapbayr") {
    # Compilar y verificar el modelo en formato mrgsolve
    my_model <- mcode(model_name, model_code)
    if (check_compile) {
      check_model <- check_mapbayr_model(my_model, check_compile = TRUE)
      message("Model is ok for estimation")
      if (is.null(check_model)) {
        message("Check mrg model")
      }
    }
    # Funcion auxiliar para Que vamos a
    verificar_OCC(model_code)

    # Asegurarse que la columna OCC y CMT existen en la base de datos
    if (!"OCC" %in% names(data)) {
      stop(" 'OCC' column is mandatory in the base data.")
    }

    if (!"CMT" %in% names(data)) {
      stop(" 'CMT' column is mandatory in the base data.")
    }
    # Definir el número de OCC si no está especificado
    if (is.null(num_occ)) {
      num_occ <- length(unique(data$OCC))
    } else {
      num_occ <- min(num_occ, length(unique(data$OCC)))
    }

    # Definir el número de IDs si no está especificado
    if (is.null(num_ids)) {
      num_ids <- length(unique(data$ID))
    } else {
      if (sampling) {
        # Muestrear IDs aleatoriamente sin reposición
        selected_ids <- sample(unique(data$ID), size = min(num_ids,
                                                           length(unique(data$ID))), replace = FALSE)
        data <- data %>% filter(ID %in% selected_ids)
      } else {
        num_ids <- min(num_ids, length(unique(data$ID)))
        selected_ids <- unique(data$ID)[1:num_ids]
        data <- data %>% filter(ID %in% selected_ids)
      }
    }

    # Filtrar los datos hasta el OCC especificado
    filtered_data <- data %>% filter(OCC <= num_occ)

    # Crear la lista de bases de datos por OCC que luego va a ser empleada
    # en la determinacion de los MAPs
    list_df_basedata <- list()
    if(evaluation_type=="Progressive")
    {
      for (i in 1:num_occ) {
        nombre_vector <- paste0("dfOCC", i)
        list_df_basedata[[nombre_vector]] <- filtered_data %>% filter(OCC <= i)
      }
    }
    else if (evaluation_type=="Most_Recent_Progressive")
    {
      for (i in 1:num_occ) {
        nombre_vector <- paste0("dfOCC", i)
        list_df_basedata[[nombre_vector]] <- filtered_data %>% filter(OCC == i)
      }
    }
    else if (evaluation_type=="Cronologic_Ref") ##### En este caso loopeo hasta occ_ref no necesito mas
    {
      for (i in 1:occ_ref) {
        nombre_vector <- paste0("dfOCC", i)
        list_df_basedata[[nombre_vector]] <- filtered_data %>% filter(OCC <= i)
      }

    }
    else if (evaluation_type== "Most_Recent_Ref") ### VER BIEN ESTA PARTE DEL CODIGO
      for (i in occ_ref:1) {
        nombre_vector <- paste0("dfOCC", i)
        list_df_basedata[[nombre_vector]] <- filtered_data %>% filter(OCC <= i)
      }
    # Paso 4.1: Generar los posibles tratamientos "a posteriori" para cada OCC
    list_ttos <- list()
    # add an if else sentece if data has ss or not , then how to compute ev tables
    if("SS" %in% names(data)|| "ss" %in% names(data)) {
    if (is.null(occ_ref)) {
      for (n in 2:num_occ) {
        vector_ttos <- paste0("tto_", n)
        list_ttos[[vector_ttos]] <- filtered_data %>% filter(OCC == n)

        # Generar los eventos para cada tratamiento y cada ID
        num_ids_ttos <- length(unique(list_ttos[[vector_ttos]]$ID))
        lista_ttos_occ <- list()
        for (ids in 1:num_ids_ttos) {
          vector_eventos <- paste0("ev.tto.occ", n, "_ID", ids)
          lista_ttos_occ[[vector_eventos]] <- list_ttos[[vector_ttos]] %>%
            filter(ID == ids)  ##### REMOVE OF EVID==1 to get all times for simulation
        }

        # Guardar los tratamientos por OCC
        list_ttos[[paste0("tto_occ_", n)]] <- lista_ttos_occ
      }
    }
    else {
      vector_ttos <- paste0("tto_", occ_ref)
      list_ttos[[vector_ttos]] <- filtered_data %>% filter(OCC == occ_ref)

      # Generar los eventos para cada tratamiento y cada ID
      num_ids_ttos <- length(unique(list_ttos[[vector_ttos]]$ID))
      lista_ttos_occ <- list()
      for (ids in 1:num_ids_ttos) {
        vector_eventos <- paste0("ev.tto.occ", occ_ref, "_ID", ids)
        lista_ttos_occ[[vector_eventos]] <- list_ttos[[vector_ttos]] %>%
          filter(ID == ids) ##### REMOVE OF EVID==1 to get all times for simulation
      }

      # Guardar los tratamientos por OCC
      list_ttos[[paste0("tto_occ_", occ_ref)]] <- lista_ttos_occ
    }
    }
    else {
      if (is.null(occ_ref)) {
        for (n in 2:num_occ) {
          vector_ttos <- paste0("tto_", n)
          list_ttos[[vector_ttos]] <- filtered_data %>% filter(OCC <= n)

          # Generar los eventos para cada tratamiento y cada ID
          num_ids_ttos <- length(unique(list_ttos[[vector_ttos]]$ID))
          lista_ttos_occ <- list()
          for (ids in 1:num_ids_ttos) {
            vector_eventos <- paste0("ev.tto.occ", n, "_ID", ids)
            lista_ttos_occ[[vector_eventos]] <- list_ttos[[vector_ttos]] %>%
              filter(ID == ids)  ##### REMOVE OF EVID==1 to get all times for simulation
          }

          # Guardar los tratamientos por OCC
          list_ttos[[paste0("tto_occ_", n)]] <- lista_ttos_occ
        }
      }
      else {
        vector_ttos <- paste0("tto_", occ_ref)
        list_ttos[[vector_ttos]] <- filtered_data %>% filter(OCC == occ_ref)

        # Generar los eventos para cada tratamiento y cada ID
        num_ids_ttos <- length(unique(list_ttos[[vector_ttos]]$ID))
        lista_ttos_occ <- list()
        for (ids in 1:num_ids_ttos) {
          vector_eventos <- paste0("ev.tto.occ", occ_ref, "_ID", ids)
          lista_ttos_occ[[vector_eventos]] <- list_ttos[[vector_ttos]] %>%
            filter(ID == ids) ##### REMOVE OF EVID==1 to get all times for simulation
        }

        # Guardar los tratamientos por OCC
        list_ttos[[paste0("tto_occ_", occ_ref)]] <- lista_ttos_occ
      }

    }

    # Paso 4.2: Generar los tratamientos "a priori" para OCC=1 o OCC=ref

    list_apriori <- list()

      occ_apriori<- ifelse(is.null(occ_ref),1,occ_ref)
      vector_ttos <- paste0("tto_", occ_apriori)
      apriori_data <- filtered_data %>% filter(OCC== occ_apriori)
      list_apriori[[vector_ttos]] <- apriori_data

      # Generar los eventos para cada tratamiento y cada ID
      num_ids_apriori <- length(unique(list_apriori[[vector_ttos]]$ID))
      lista_ttos_apriori_occ <- list()
      for (ids in 1:num_ids_ttos) {
        vector_eventos <- paste0("ev.tto.occ", occ_apriori, "_ID", ids)
        lista_ttos_apriori_occ[[vector_eventos]] <- apriori_data %>%
          filter(ID == ids)  ##### REMOVE OF EVID==1 to get all times for simulation
      }

      # Guardar los tratamientos por OCC
      list_apriori[[paste0("apriori_occ_", occ_apriori)]] <- lista_ttos_apriori_occ

    # Paso 5: Correr las estimaciones MAP para cada conjunto de datos filtrados
    list_map <- list()

    if(evaluation_type=="Progressive") {
      for (j in 1:(num_occ - 1)) {
        previous_numbers <- paste0(1:j, collapse = "_")
        map.result <- paste0("map.estimation.occ_0_",previous_numbers)
        list_map[[map.result]] <- mapbayr::mapbayest(my_model,
                                                     data = list_df_basedata[[paste0("dfOCC", j)]],
                                                     method = method)
      }
    }

    else if (evaluation_type== "Most_Recent_Progressive")  {
      for (j in 1:(num_occ - 1)) {
        map.result <- paste0("map.estimation.occ_", j)
        list_map[[map.result]] <- mapbayr::mapbayest(my_model,
                                                     data = list_df_basedata[[paste0("dfOCC", j)]],
                                                     method = method)
      }
    }
    else if (evaluation_type== "Cronologic_Ref")  {
      for (j in 1:(occ_ref - 1)) {
        previous_numbers <- paste0(1:j, collapse = "_")
        map.result <- paste0("map.estimation.occ_0_",previous_numbers)
        list_map[[map.result]] <- mapbayr::mapbayest(my_model,
                                                     data = list_df_basedata[[paste0("dfOCC", j)]],
                                                     method = method)
      }
    }
    else if (evaluation_type== "Most_Recent_Ref")  {
      for (j in (occ_ref - 1):1) {
        previous_numbers <- paste0((occ_ref-1):j, collapse = "_")
        map.result <- paste0("map.estimation.occ_",previous_numbers)
        list_map[[map.result]] <- mapbayr::mapbayest(my_model,
                                                     data = list_df_basedata[[paste0("dfOCC", j)]],
                                                     method = method)
      }
    }

    return(list(
      data_by_occ = list_df_basedata,
      treatments_by_occ = list_ttos,
      apriori_treatments = list_apriori,
      map_estimations = list_map,
      eval_type = evaluation_type,
      pop_model = my_model
    ))
  }

  # else if (tool == "lixoftConnectors") {
  #   dat(file = file_mlxtran)
  #   pp <- protodata(file = file_mlxtran, names_occ = names_occ)
  #
  #   names(pp[[1]])[which(names(pp[[1]]) == names_id)] <- 'ID'
  #   names(pp[[1]])[which(names(pp[[1]]) == names_time)] <- 'TIME'
  #   names(pp[[1]])[which(names(pp[[1]]) == names_evid)] <- 'EVID'
  #
  #   for (o in 1:occ) {
  #     estimation_occ(occ = o,
  #                    datos = pp[[1]],
  #                    file = file_mlxtran)
  #   }
  #
  #   lixoftConnectors::initializeLixoftConnectors(software = "simulx", force=TRUE)
  #   lixoftConnectors::importProject(file_mlxtran)
  #
  #   out <- vector(mode = 'list', length = occ) # no simulation for last occ
  #
  #   for (o in 0:(occ-1) ) {
  #
  #     nn <- pp[[1]] %>%
  #       filter(OCC == c(o+1), EVID==0) %>%
  #       select(ID, TIME, DV, OCC)  |>
  #       setNames( c('ID', 'time', 'DV', 'OCC') )
  #
  #     if (o == 0) {
  #       out[[1]] <- rio::import("priorPred.csv")
  #     } else {
  #       ss <- simulation_occ(file = file_mlxtran, newD = nn[,1:2], o = o)
  #       ss$data = nn
  #       out[[o+1]] <- ss
  #     }
  #
  #  }
#     names(out) <- paste0('simOCC_', 1:occ )
#     return(out)
#   }

}
