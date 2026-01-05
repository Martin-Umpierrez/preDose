#' Compute metrics by occasion
#'
#' @param x Object containing individual simulations
#' @param ... Additional arguments
#' @export
metric_occ <- function(x, ...) {
  UseMethod("metric_occ")
}
