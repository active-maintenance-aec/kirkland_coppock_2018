# kirkland_coppock_2018/maintained/figure_5_mturk_het_fx_candidate_pref.R
# Output: output/figure_5_mturk_het_fx_candidate_pref.{pdf,png,csv}
# Depends on: helpers.R
# Description: MTurk heterogeneous effects on candidate preference by respondent
#   party identification (Figure 5).

source(here::here("maintained", "helpers.R"))

# Each respondent subgroup is estimated separately, as in the archive: the three
# panels are refit within Democrats and again within Republicans.
plot_df <- bind_rows(
  election_type_panels(filter(mturk_clean, democrat == 1), dv = "win",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(party = "Democrats"),
  election_type_panels(filter(mturk_clean, republican == 1), dv = "win",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(party = "Republicans")
) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference")) |>
  mutate(party = factor(party, levels = c("Democrats", "Republicans")))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1),
                   by_party = TRUE)

save_figure(g, plot_df, "figure_5_mturk_het_fx_candidate_pref", width = 10, height = 7)
