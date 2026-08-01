# kirkland_coppock_2018/maintained/text_observational_experience_advantage.R
# Output: output/text_observational_experience_advantage.csv
# Depends on: helpers.R, recovered/observational_mayors_replication.rdata
# Description: The in-text follow-up to Table 1, restricted to the elections in which
#   the two candidates had different levels of political experience: how often the
#   more experienced candidate won, by ballot type, and the test of the difference.
#
# No deposited or recovered script computes these numbers. They are reconstructed
# here from the recovered data by the only reading of "candidates have different
# levels of political experience" the data supports.

source(here::here("maintained", "helpers.R"))

load(here("recovered", "observational_mayors_replication.rdata"))
mayors <- ungroup(mayors)

# One row per election, winner and runner-up side by side ----
# experience_recoded is an ordered set of offices, so "more experienced" is a
# comparison of the two candidates' positions in that ordering.
contested <- mayors |>
  group_by(contest_id) |>
  summarize(winner = experience_recoded[win == 1],
            runner_up = experience_recoded[win == 0],
            partisan = unique(partisan),
            .groups = "drop") |>
  filter(winner != runner_up) |>
  mutate(more_experienced_won = as.integer(as.integer(winner) > as.integer(runner_up)),
         nonpartisan = as.integer(partisan == "NP"))

by_type <- contested |>
  group_by(ballot = if_else(nonpartisan == 1, "Nonpartisan", "Partisan")) |>
  summarize(n_elections = n(),
            pct_more_experienced_won = 100 * mean(more_experienced_won),
            .groups = "drop")

difference <- tidy(lm_robust(more_experienced_won ~ nonpartisan, data = contested)) |>
  filter(term == "nonpartisan")

result <- tibble(
  n_elections_total = nrow(contested),
  pct_nonpartisan = by_type$pct_more_experienced_won[by_type$ballot == "Nonpartisan"],
  pct_partisan = by_type$pct_more_experienced_won[by_type$ballot == "Partisan"],
  difference_pp = 100 * difference$estimate,
  p_value_hc2 = difference$p.value,
  p_value_chisq = chisq.test(table(contested$nonpartisan,
                                   contested$more_experienced_won))$p.value
)

write_csv(result, here("maintained", "output",
                       "text_observational_experience_advantage.csv"))
