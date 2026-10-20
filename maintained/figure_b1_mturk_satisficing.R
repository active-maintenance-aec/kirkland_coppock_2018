# kirkland_coppock_2018/maintained/figure_b1_mturk_satisficing.R
# Output: output/figure_b1_mturk_satisficing.{pdf,png,csv}
# Depends on: helpers.R
# Description: MTurk partisan elections, candidate preference, split by whether the
#   two candidates share a party (Appendix Figure B.1, the satisficing check).

source(here::here("maintained", "helpers.R"))

plot_df <- same_party_panels(mturk_clean, dv = "win",
                             cluster_col = "resp_mturkid", weighted = FALSE) |>
  finalize_plot_df(panel_levels = c("Same Party", "Different Parties", "Difference"))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1))

save_figure(g, plot_df, "figure_b1_mturk_satisficing", width = 10, height = 7)
