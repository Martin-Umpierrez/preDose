#' seect_best_models
#'
#' Select Top Ranked Models
#'
#' #' This function selects the best models from a dataframe of metrics by models based on a specified ranking metric
#' (e.g., minimum, maximum, or absolute value of a given metric). It can filter the best models by the
#' `OCC` value if specified, or return the top models for all `OCC` values.
#'
#' @param data A dataframe obtained from `combine_metrics()`, containing the combined metrics data.
#' @param metric A character string specifying the metric to use for ranking.
#' @param top_n An integer specifying the number of top models to select per OCC.
#' @param occ_eval A numeric or character value specifying the `OCC` to filter the models by. Default is `NULL`, which means no filtering by `OCC`.
#' @param rank_criteria A character string specifying how to rank the models:
#'   - `'min'`: Select models with the lowest metric values (e.g., MAIPE).
#'   - `'max'`: Select models whose metric values are higher (e.g., IF30).
#'   - `'abs'` : Selects models with the smallest absolute metric values (eg rBIAS)
#'
#' @return A data frame with the top-ranked models for each OCC.
#' @export
#'
#' @examples
#' top_models <- select_top_models(combined_results, metric = 'MAIPE', top_n = 3, occ_eval=2, rank_criteria = 'min')
select_best_models <-
  function(data, metric, top_n = 3, occ_eval=NULL , rank_criteria = 'min') {
    if (is.null(occ_eval)){
      ranked_models <- data %>%
        group_by(OCC) %>%
        arrange(
          if (rank_criteria == 'min') !!sym(metric)
          else if (rank_criteria == 'max') desc(!!sym(metric))
          else abs(!!sym(metric))
        ) %>%
        slice_head(n = top_n) %>%
        ungroup()
    }
    else {
      ranked_models<- data %>%
        group_by(OCC) %>%
        arrange(
          if (rank_criteria == 'min') !!sym(metric)
          else if (rank_criteria == 'max') desc(!!sym(metric))
          else abs(!!sym(metric))
        ) %>%
        slice_head(n = top_n) %>%
        filter(OCC==occ_eval) %>%
        ungroup()

    }
    return(ranked_models)
  }
