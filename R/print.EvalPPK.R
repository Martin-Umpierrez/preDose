#' print method for EvalPPK class
#'
#' @param x EvalPPK object
#' @param ... additional arguments (not used)
#'
#' @export
print.EvalPPK <- function(x, ...) {
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
  print( x$metrics$metrics_means )
  cat(rep("=", nn + 4), "\n", sep = "")
}
