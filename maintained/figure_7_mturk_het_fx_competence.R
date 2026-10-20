# kirkland_coppock_2018/maintained/figure_7_mturk_het_fx_competence.R
# Output: output/figure_7_mturk_het_fx_competence.{pdf,png,csv}
# Depends on: helpers.R
# Description: MTurk heterogeneous effects on competence ratings by respondent
#   party identification (Figure 7).

source(here::here("maintained", "helpers.R"))

plot_df <- bind_rows(
  election_type_panels(filter(mturk_clean, democrat == 1), dv = "comp",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(party = "Democrats"),
  election_type_panels(filter(mturk_clean, republican == 1), dv = "comp",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(party = "Republicans")
) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference")) |>
  mutate(party = factor(party, levels = c("Democrats", "Republicans")))

g <- conjoint_plot(plot_df, xlim = c(-15, 15), by_party = TRUE)

save_figure(g, plot_df, "figure_7_mturk_het_fx_competence", width = 10, height = 7)
