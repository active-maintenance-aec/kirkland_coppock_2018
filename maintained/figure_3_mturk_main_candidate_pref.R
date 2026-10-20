# kirkland_coppock_2018/maintained/figure_3_mturk_main_candidate_pref.R
# Output: output/figure_3_mturk_main_candidate_pref.{pdf,png,csv}
# Depends on: helpers.R
# Description: MTurk main analysis, candidate preference, by election type (Figure 3).

source(here::here("maintained", "helpers.R"))

# The MTurk sample carries no survey weights, so this figure is unweighted.
plot_df <- election_type_panels(mturk_clean, dv = "win",
                                cluster_col = "resp_mturkid", weighted = FALSE) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1))

save_figure(g, plot_df, "figure_3_mturk_main_candidate_pref", width = 10, height = 7)
