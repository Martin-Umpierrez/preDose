#' metrics_Plot
#'
#' Generate Different Type of Metrics Plots
#'
#' This function creates various types of metrics plots for evaluating popPK Models , such as rBias, MAIPE, and IF20/IF30 values.
#'
#' @param mm A list containing data frames with the required  metrics. Typically, `mm[[1]]` and `mm[[2]]` contain relevant data. Values comes from results from [metrics_occ()] function
#' @param type A character string specifying the type of plot to generate. Options are:
#'   \itemize{
#'     \item \code{"bias_barplot"}: Bar plot of relative bias (\code{rBIAS}) with error bars.
#'     \item \code{"MAIPE_barplot"}: Bar plot of MAIPE values.
#'     \item \code{"bias_boxplot"}: Box plot of IPE values.
#'     \item \code{"bias_violin"}: Violin plot of IPE values.
#'     \item \code{"IF20_plot"}: Bar plot of IF20 values with reference line at 35%.
#'     \item \code{"IF30_plot"}: Bar plot of IF30 values with reference line at 50%.
#'   }
#'
#' @return A ggplot object corresponding to the selected plot type.
#'
#' @details
#' The function utilizes ggplot2 for visualization and `scale_fill_brewer(palette = "Dark2")` for consistent color schemes.
#'
#' @import ggplot2 dplyr
#' @importFrom scales brewer_pal
#' @export
#'
#' @examples
#' \dontrun{
#' data_list <- list(
#'   data.frame(OCC = rep(1:3, each = 10), IPE = rnorm(30)),
#'   data.frame(OCC = rep(1:3, each = 10), rBIAS = rnorm(30, 0, 10),
#'              rBIAS_lower = rnorm(30, -5, 5), rBIAS_upper = rnorm(30, 5, 5),
#'              MAIPE = rnorm(30, 20, 5), IF20 = runif(30, 20, 40),
#'              IF30 = runif(30, 30, 60))
#' )
#' plot <- metrics_Plot(data_list, type = "bias_barplot")
#' print(plot)
#' }

metrics_Plot <-
function(mm, type = c('bias_barplot',
                                     'MAIPE_barplot',
                                     'bias_boxplot',
                                     'bias_violin',
                                     'IF20_plot',
                                     'IF30_plot',)) {
  pp <- NULL

  if (type == 'bias_barplot') {
    pp <- mm[[2]] |>
      mutate(OCC = factor(OCC) ) |>
      ggplot( aes(x =OCC, y = rBIAS, fill = OCC) ) +
      geom_col( ) +
      geom_errorbar(aes(ymin = rBIAS_lower, ymax = rBIAS_upper), width = 0.2) +
      geom_hline(data= data.frame(yy =c(-20, 20)), aes(yintercept= yy), linetype = "dashed", color='firebrick') +
      scale_fill_brewer(palette = 'Dark2')
  } else if (type == 'MAIPE_barplot') {
    pp <-   mm[[2]] |>  # rBIAS_boxplot
      mutate(OCC = factor(OCC) ) |>
      ggplot (aes(x=OCC, y=MAIPE, fill=OCC)) + geom_boxplot() +
      geom_hline(data= data.frame(yy =c(30)), aes(yintercept= yy), linetype = "dashed", color='firebrick') +
      scale_fill_brewer(palette = 'Dark2')
  } else if (type == 'bias_boxplot') {
    pp <-   mm[[1]] |>  # rBIAS_boxplot
      mutate(OCC = factor(OCC) ) |>
      ggplot (aes(x=OCC, y=IPE, fill=OCC)) + geom_boxplot() +
      geom_hline(data= data.frame(yy =c(-20, 20)), aes(yintercept= yy), linetype = "dashed", color='firebrick') +
      scale_fill_brewer(palette = 'Dark2')
  } else if (type == 'bias_violin') {
    pp <- mm[[1]] |> # rBIAS_violinplot
      mutate(OCC = factor(OCC) ) |>
      ggplot( aes(x=OCC, y=IPE, fill=OCC)) + geom_violin() +
      scale_fill_brewer(palette = 'Dark2')
  } else if (type ==  'IF20_plot') {
    pp <- mm[[2]] |> #  IF20_plot
      mutate(OCC = factor(OCC) ) |>
      ggplot(aes(x=OCC, y=IF20))+
      geom_col( aes(fill=OCC) )+
      geom_hline( aes(yintercept= 35), linetype = "dashed", colour= 'firebrick') +
      scale_fill_brewer(palette = "Dark2")+
      labs(title="IF20- Bayesian Forecasting",y="IF20(%)")+
      theme(plot.title = element_text(size = rel(1), colour = "black")) +
      theme(plot.title = element_text(size = 10, face = "bold"))
  }
  else if (type ==  'IF30_plot') {
    pp <- mm[[2]] |> #  IF20_plot
      mutate(OCC = factor(OCC) ) |>
      ggplot(aes(x=OCC, y=IF30))+
      geom_col( aes(fill=OCC) )+
      geom_hline( aes(yintercept= 50), linetype = "dashed", colour= 'firebrick') +
      scale_fill_brewer(palette = "Dark2")+
      labs(title="IF30- Bayesian Forecasting",y="IF20(%)")+
      theme(plot.title = element_text(size = rel(1), colour = "black")) +
      theme(plot.title = element_text(size = 10, face = "bold"))
  }
  return(pp)
}
