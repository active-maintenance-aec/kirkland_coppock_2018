# kirkland_coppock_2018/maintained/figure_c4_yougov_main_competence.R
# Output: output/figure_c4_yougov_main_competence.{pdf,png,csv}
# Depends on: helpers.R
# Description: YouGov main analysis, competence ratings, by election type
#   (Appendix Figure C.4).

source(here::here("maintained", "helpers.R"))

# Weighted, matching the archive (yougov_replication.R, lines 484, 490 and 497).
plot_df <- election_type_panels(yougov_clean, dv = "comp",
                                cluster_col = "caseid", weighted = TRUE) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-15, 15))

save_figure(g, plot_df, "figure_c4_yougov_main_competence", width = 9, height = 9)
