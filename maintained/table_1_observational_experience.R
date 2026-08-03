# kirkland_coppock_2018/maintained/table_1_observational_experience.R
# Output: output/table_1_observational_experience.csv,
#   output/text_observational_chisq.csv,
#   output/text_observational_dataset_description.csv
# Depends on: helpers.R, recovered/observational_mayors_replication.rdata
# Description: Political experience of the winning candidate in 1,010 US mayoral
#   elections, by whether the ballot was partisan (Table 1), and the chi-squared test
#   printed beneath it.
#
# The data and the script that built this table are absent from the Dataverse
# deposit even though its README lists both. They came from the authors and live in
# recovered/, which the repository does commit because it exists nowhere else.

source(here::here("maintained", "helpers.R"))

# mayors was saved by a dplyr old enough that the grouping structure survives the
# round trip; without ungroup() the summarize below silently keeps the stale groups.
load(here("recovered", "observational_mayors_replication.rdata"))
mayors <- ungroup(mayors)

# The dataset as the article describes it ----
# The paragraph introducing Table 1 states how many elections the dataset holds, how
# many municipalities they fall in, and the years they span. The variable list is
# recorded here too, because the sentence after Table 1 reports candidates' careers
# and nothing in the file records one.
dataset_description <- tibble(
  n_elections = n_distinct(mayors$contest_id),
  n_candidates = nrow(mayors),
  n_municipalities = n_distinct(mayors$fipsid),
  year_first = min(mayors$year),
  year_last = max(mayors$year),
  n_variables = ncol(mayors),
  variables = paste(names(mayors), collapse = "; ")
)

write_csv(dataset_description,
          here("maintained", "output", "text_observational_dataset_description.csv"))

experience_labels <- c(
  "no experience" = "No previous political experience",
  "council" = "City legislator",
  "county_elect" = "County legislator",
  "state_elect" = "State legislator",
  "us_elect" = "US legislator",
  "mayor" = "Mayor"
)

# One row per election, carrying the winner's experience ----
election_level <- mayors |>
  group_by(contest_id) |>
  summarize(winner_experience = experience_recoded[win == 1],
            partisan = unique(partisan),
            .groups = "drop")

# Table 1 ----
# The deposit codes the ballot type as "NP" and "P".
counts <- election_level |>
  count(winner_experience, partisan) |>
  mutate(experience = unname(experience_labels[as.character(winner_experience)]))

# The Total row's percentage is the column total taken as a share of itself, which
# is 100 by construction. Summing the six rounded row percentages instead would
# print 101 in the nonpartisan column.
table_1 <- counts |>
  bind_rows(summarize(counts, experience = "Total", n = sum(n), .by = partisan)) |>
  mutate(pct = round(100 * n / sum(n[experience != "Total"])), .by = partisan) |>
  pivot_wider(id_cols = experience, names_from = partisan,
              values_from = c(n, pct)) |>
  rename(n_nonpartisan = n_NP, pct_nonpartisan = pct_NP,
         n_partisan = n_P, pct_partisan = pct_P) |>
  mutate(experience = factor(experience,
                             levels = c(unname(experience_labels), "Total"))) |>
  arrange(experience)

write_csv(table_1, here("maintained", "output",
                        "table_1_observational_experience.csv"))

# Chi-squared test ----
# The archive calls chisq.test(simulate.p.value = TRUE) and sets no seed, so its
# p-value is a Monte Carlo draw rather than a fixed quantity. Reporting one seeded
# draw would hide that, so this records the asymptotic p-value, which is exact, and
# the spread of 500 replications of the archive's own simulation, which is what the
# published 0.002 has to be read against.
experience_table <- with(election_level, table(winner_experience, partisan))
asymptotic <- suppressWarnings(chisq.test(experience_table))

set.seed(20180101)
simulated_p <- replicate(500,
  chisq.test(experience_table, simulate.p.value = TRUE)$p.value)

chisq_df <- tibble(
  statistic = unname(asymptotic$statistic),
  df = unname(asymptotic$parameter),
  p_asymptotic = asymptotic$p.value,
  p_simulated_min = min(simulated_p),
  p_simulated_median = median(simulated_p),
  p_simulated_max = max(simulated_p),
  share_rounding_to_0.002 = mean(round(simulated_p, 3) == 0.002)
)

write_csv(chisq_df, here("maintained", "output", "text_observational_chisq.csv"))
