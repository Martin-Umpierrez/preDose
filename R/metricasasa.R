metrics_Plot2 <-
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
