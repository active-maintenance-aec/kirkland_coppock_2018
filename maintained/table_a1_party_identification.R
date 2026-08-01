# kirkland_coppock_2018/maintained/table_a1_party_identification.R
# Output: output/table_a1_party_identification.csv
# Depends on: helpers.R
# Description: The respondent party identification panel of Appendix Table A.1, plus
#   the two sample sizes reported in its note.
#
# Only this panel of Table A.1 can be rebuilt from the deposit. The table also
# reports respondent race, gender, ideology, education and age, and neither
# deposited data file carries those variables; the deposited files hold party
# identification and nothing else about the respondent.

source(here::here("maintained", "helpers.R"))

# One row per respondent ----
mturk_respondents <- distinct(mturk_clean, resp_mturkid, .keep_all = TRUE)
yougov_respondents <- distinct(yougov_clean, caseid, .keep_all = TRUE)

# YouGov proportions are weighted, as the table's note states; MTurk has no weights.
mturk_shares <- mturk_respondents |>
  count(party_id = resp_pid_3_text) |>
  mutate(sample = "mTurk", proportion = n / sum(n))

yougov_shares <- yougov_respondents |>
  group_by(party_id = resp_pid_3_text) |>
  summarize(n = n(), weighted_n = sum(weight), .groups = "drop") |>
  mutate(sample = "YouGov", proportion = weighted_n / sum(weighted_n))

table_a1 <- bind_rows(mturk_shares, yougov_shares) |>
  mutate(n_respondents = if_else(sample == "mTurk",
                                 nrow(mturk_respondents), nrow(yougov_respondents)),
         proportion = round(proportion, 3)) |>
  select(sample, party_id, n_respondents, proportion) |>
  arrange(desc(sample), party_id)

write_csv(table_a1, here("maintained", "output", "table_a1_party_identification.csv"))
