# kirkland_coppock_2018/maintained/figure_b2_yougov_satisficing.R
# Output: output/figure_b2_yougov_satisficing.{pdf,png,csv}
# Depends on: helpers.R
# Description: YouGov partisan elections, candidate preference, split by whether the
#   two candidates share a party (Appendix Figure B.2, the satisficing check).

source(here::here("maintained", "helpers.R"))

# Weighted, matching the archive (yougov_replication.R, lines 996, 1000 and 1005).
plot_df <- same_party_panels(yougov_clean, dv = "win",
                             cluster_col = "caseid", weighted = TRUE) |>
  finalize_plot_df(panel_levels = c("Same Party", "Different Parties", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1))

save_figure(g, plot_df, "figure_b2_yougov_satisficing", width = 9, height = 9)
