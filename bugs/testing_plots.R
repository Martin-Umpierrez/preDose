
tt <- c("bias_barplot", "MAIPE_barplot", "bias_boxplot", "bias_violin",
    "bias_dotplot", "bias_density", "IF20_plot", "IF30_plot")

 metrics_Plot(res$metrics, type = tt[1] )

mm <- res$metrics


# ----------------------------------------------

# Ver el rBIAS o IPE medio, pointrange para media y su intervalo 
regions <- data.frame(
  xmin = rep(-Inf,4),
  xmax = rep(Inf,4),
  ymin = c(-Inf, -30, 20, 30),
  ymax = c(-30, -20,  30, Inf),
  region = c("+30","+20","+20","+30")
)

ggplot(mm[[2]], aes( x =OCC, y = rBIAS ) ) + 
   #Add background regions first (so they appear behind points) 
  geom_rect(data = regions, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, 
  fill = region), alpha = 0.3, inherit.aes = FALSE) +
  geom_pointrange( aes( ymax=rBIAS_upper, ymin=rBIAS_lower) ) + 
  scale_fill_manual(values = c( "+20" = "wheat", 
                              "+30" = "Lightcoral")) + 
  labs(x='Ocassion', fill='')+
  theme_bw()

# Ver la distribución del IPE por ocasion con raincluod

library(ggdist)
 #ggplot(data, aes(x = group, y = value, fill = group)) +
  ggplot(mm[[1]], aes( x =factor(OCC), y = IPE ) ) +
  # Cloud (density)
  stat_halfeye(adjust = 0.5, width = 0.5, .width = 0,
               justification = -0.5, point_colour = NA) +
  # Rain (individual points)
  geom_point(size = 1.3, alpha = 0.3,
             position = position_jitter(seed = 1, width = 0.1)) +
  # Box plot
  geom_boxplot(width = 0.4, outlier.shape = NA, alpha = 0.5, color='darkseagreen') +
  geom_hline(data= data.frame(yy =c(-30, 30)), aes(yintercept= yy), linetype = "dashed", color='Lightcoral') +
  theme_bw() +
  theme(legend.position = "none") + 
  scale_interval_color_discrete()


# Mirar errores vs predicciones para cada ocasion
mm[[1]] |> 
  mutate(error = Ind_Prediction - DV) |> 
  ggplot() + 
  geom_point( aes(y=error, x=Ind_Prediction)) + 
  facet_wrap(~OCC, scales='free')


# para los dibujos de IF20 y IF30
mm[[1]] |> 
  mutate( 
    tramo = case_when(
     abs(IPE) <= 20 ~ 'Good', 
     abs(IPE)>20 & abs(IPE)<= 30 ~ '20+',
     abs(IPE) > 30 ~ '30+',
     TRUE ~ 'cucu'
    )) |>
  mutate(tramo = factor(tramo, levels=c('30+', '20+', 'Good') ) ) |> 
  ggplot() + 
  geom_bar(aes(x=OCC, fill=tramo), position = 'fill' , alpha=.7) + 
  scale_fill_manual( values = c('Lightcoral', 'wheat', 'darkseagreen')) + 
  theme_bw() + 
  theme(panel.grid.major = element_line(linewidth = .5, linetype=2, color='grey30'))
