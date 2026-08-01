# kirkland_coppock_2018/maintained/figure_4_yougov_main_candidate_pref.R
# Output: output/figure_4_yougov_main_candidate_pref.{pdf,png,csv}
# Depends on: helpers.R
# Description: YouGov main analysis, candidate preference, by election type (Figure 4).

source(here::here("maintained", "helpers.R"))

# The archive weights this figure (yougov_replication.R, lines 34, 40 and 47), and
# clusters on caseid.
plot_df <- election_type_panels(yougov_clean, dv = "win",
                                cluster_col = "caseid", weighted = TRUE) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1))

save_figure(g, plot_df, "figure_4_yougov_main_candidate_pref", width = 9, height = 9)
