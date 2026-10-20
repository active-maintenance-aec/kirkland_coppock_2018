# kirkland_coppock_2018/maintained/figure_c3_mturk_main_competence.R
# Output: output/figure_c3_mturk_main_competence.{pdf,png,csv}
# Depends on: helpers.R
# Description: MTurk main analysis, competence ratings, by election type
#   (Appendix Figure C.3).

source(here::here("maintained", "helpers.R"))

plot_df <- election_type_panels(mturk_clean, dv = "comp",
                                cluster_col = "resp_mturkid", weighted = FALSE) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-15, 15))

save_figure(g, plot_df, "figure_c3_mturk_main_competence", width = 10, height = 7)
