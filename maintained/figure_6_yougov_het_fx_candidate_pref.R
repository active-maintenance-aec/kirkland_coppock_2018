# kirkland_coppock_2018/maintained/figure_6_yougov_het_fx_candidate_pref.R
# Output: output/figure_6_yougov_het_fx_candidate_pref.{pdf,png,csv}
# Depends on: helpers.R
# Description: YouGov heterogeneous effects on candidate preference by respondent
#   party identification (Figure 6).

source(here::here("maintained", "helpers.R"))

# Unweighted, unlike Figure 4. The archive passes weights to the YouGov main-effect
# models but not to the subgroup models behind this figure (yougov_replication.R,
# lines 121 to 292). The rewrite keeps the archive's specification; weighting these
# models would be an analytical change rather than a maintenance fix, and it moves
# individual estimates by up to 0.04.
plot_df <- bind_rows(
  election_type_panels(filter(yougov_clean, democrat == 1), dv = "win",
                       cluster_col = "caseid", weighted = FALSE) |>
    mutate(party = "Democrats"),
  election_type_panels(filter(yougov_clean, republican == 1), dv = "win",
                       cluster_col = "caseid", weighted = FALSE) |>
    mutate(party = "Republicans")
) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference")) |>
  mutate(party = factor(party, levels = c("Democrats", "Republicans")))

g <- conjoint_plot(plot_df, xlim = c(-0.4, 0.4), breaks = round(seq(-0.3, 0.3, 0.1), 1),
                   by_party = TRUE)

save_figure(g, plot_df, "figure_6_yougov_het_fx_candidate_pref", width = 9, height = 9)
