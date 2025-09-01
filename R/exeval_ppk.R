#' External evaluation for Population Pharmacokinetic (PPK) Models
#'
#' Performs external evaluation of PPK models by conducting MAP estimations and individual simulations
#' for each ocasion using different evaluation strategies (see evaluation_type)
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
#' @param assessment Character string. Specifies the type of prediction to perform. Options are:
#'   \itemize{
#'     \item "a_priori": Simulates concentrations using the population model without individual data.
#'     \item "Bayesian_Forecasting": Simulates concentrations using individual parameter estimates (posterior mode).
#'     \item "Complete": Performs both a priori and Bayesian forecasting simulations.
#'   }

#'
#' @return A list containing:
#' \describe{
#'   \item{metrics}{Evaluation metrics}
#'   \item{estimations}{MAP estimation results for each subset of the data.}
#'   \item{simulation}{A list of simulation results for each occasion and individual.}
#'   \item{updates}: A list containing posterior estimations (`a.posteriori`) for each occasion.
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



exeval_ppk <-  function(model_name,
                        model_code,
                        tool = c("mapbayr", "lixoftconnectors"),### From mrg mode
                        check_compile = TRUE,
                        data,
                        num_occ = NULL, ### Para lixoft definimos solo occ
                        num_ids= NULL,
                        sampling = TRUE,
                        occ_ref = NULL , ### Se usa solo si evaluation_type es basado en una referencia
                        evaluation_type = c("Progressive", "Most_Recent_Progressive","Cronologic_Ref","Most_Recent_Ref"), ## Como se va a hacer la eval externa
                        file_mlxtran= "M2_TEST.mlxtran",
                        names_occ = "OCC",
                        names_id = "ID",
                        names_time = "TIME",
                        names_evid = "EVID",
                        method = c("L-BFGS-B", "newuoa"),
                        assessment = c("a_priori","Bayesian_forecasting", "Complete")) {

  est <- run_MAP_estimations(
    model_name,
    model_code,
    tool,
    check_compile,
    data,
    num_occ,
    num_ids,
    sampling,
    occ_ref,
    evaluation_type,
    file_mlxtran,
    names_occ,
    names_id,
    names_time,
    names_evid,
    method
  )

  updt <- actualize_model(est, evaluation_type)

  sims <- run_ind_simulations(updt, est, assessment)

  metrics <- metrics_occ(sims, assessment=assessment,tool=tool )

  argument = c('Model Name', 'Evaluation', 'Assesment')
  value    = c(model_name, match.arg(evaluation_type), match.arg(assessment))
  info = data.frame(argument, value)

  structure(
    list(metrics=metrics, estimates=est, updates=updt, simulations=sims),
    class = 'EvalPPK',
    attributes = info)

}


print.EvalPPK <- function(rr) {
  info <- attr(res, 'attributes')
  nn <- nchar(info[3,]) |> sum()
  cat(rep("=", nn + 4), "\n", sep = "")
  cat('Evaluation information')
  cat("\n")
  print(info)
  cat(rep("=", nn + 4), "\n", sep = "")
  cat("\n")
  cat(rep("=", nn + 4), "\n", sep = "")
  cat('Evaluation metrics')
  cat("\n")
  print( rr$metrics$metrics_means )
  cat(rep("=", nn + 4), "\n", sep = "")
}
