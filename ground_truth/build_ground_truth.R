# kirkland_coppock_2018/ground_truth/build_ground_truth.R
# Output: ground_truth/kirkland_coppock_2018_ground_truth.csv
# Depends on: ground_truth/published_claims.csv, maintained/output/ (run run_all.R first),
#             maintained/in_text_claims.R
# Description: Assemble the ground truth table and gate the coverage of the two
#   instruments that check this article.
#
#   ground_truth/published_claims.csv is the extraction: every numeric token in the
#   article and the online appendix, with its location and a hand-assigned type. Its
#   value_paper column holds the string the article prints and is the only place a
#   published number appears in this repository. It is a comparison target and never
#   an input to a computation, here or under maintained/.
#
#   Every other value in this file is read back out of maintained/output/, so the table
#   cannot drift from the pipeline. The derivations below are written independently of
#   the ones in maintained/in_text_claims.R, which reaches the same quantities from the
#   same files by its own route: where the two disagree, one of them is wrong.
#
#   value_script and match are NA on every row. The deposited scripts write no files
#   at all, keeping every result as an in-memory R object, and this repository ships no
#   script that re-derives those objects, so there is no archive value to read back and
#   no archive comparison to make. Filling the column from value_rewrite would record
#   the rewrite's own numbers as the archive's.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

published_claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                             show_col_types = FALSE)

table_1 <- out("table_1_observational_experience.csv")
table_a1 <- out("table_a1_party_identification.csv")
chisq <- out("text_observational_chisq.csv")
dataset <- out("text_observational_dataset_description.csv")
advantage <- out("text_observational_experience_advantage.csv")
design <- out("text_design_parameters.csv")
correlation <- out("text_mturk_yougov_correlation.csv")
policy <- out("text_policy_index_het_fx.csv")

figures <- c("figure_3_mturk_main_candidate_pref", "figure_4_yougov_main_candidate_pref",
             "figure_5_mturk_het_fx_candidate_pref", "figure_6_yougov_het_fx_candidate_pref",
             "figure_7_mturk_het_fx_competence", "figure_8_yougov_het_fx_competence",
             "figure_b1_mturk_satisficing", "figure_b2_yougov_satisficing",
             "figure_c3_mturk_main_competence", "figure_c4_yougov_main_competence") |>
  set_names() |>
  map(\(stem) out(paste0(stem, ".csv")))

f3 <- figures$figure_3_mturk_main_candidate_pref
f4 <- figures$figure_4_yougov_main_candidate_pref
f5 <- figures$figure_5_mturk_het_fx_candidate_pref
f6 <- figures$figure_6_yougov_het_fx_candidate_pref
f7 <- figures$figure_7_mturk_het_fx_competence
f8 <- figures$figure_8_yougov_het_fx_competence
fb1 <- figures$figure_b1_mturk_satisficing
fb2 <- figures$figure_b2_yougov_satisficing
fc3 <- figures$figure_c3_mturk_main_competence
fc4 <- figures$figure_c4_yougov_main_competence

# Every join goes through this, so a mismatched key cannot silently drop or duplicate.
join_checked <- function(x, y, by) {
  stopifnot(!any(duplicated(x[[by]])), !any(duplicated(y[[by]])))
  joined <- left_join(x, y, by = by)
  stopifnot(nrow(joined) == nrow(x))
  joined
}

# Estimates from a figure, base-category placeholders dropped.
drawn <- function(df, ...) {
  rows <- filter(df, ..., !is.na(estimate))
  stopifnot(nrow(rows) > 0)
  rows
}

clear_of_zero <- function(df) sum(df$conf.low > 0 | df$conf.high < 0)

design_value <- function(sample_label, parameter_name) {
  value <- design$value[design$sample == sample_label & design$parameter == parameter_name]
  stopifnot(length(value) == 1)
  value
}

# Numeric claims the pipeline reaches ----

table_1_slugs <- c("No previous political experience" = "no_previous_political_experience",
                   "City legislator" = "city_legislator",
                   "County legislator" = "county_legislator",
                   "State legislator" = "state_legislator",
                   "US legislator" = "us_legislator",
                   "Mayor" = "mayor",
                   "Total" = "total")

table_1_rows <- table_1 |>
  pivot_longer(-experience, names_to = "cell", values_to = "value_rewrite") |>
  transmute(claim_id = paste0("table_1_", table_1_slugs[experience], "_", cell),
            table_figure = "Table 1",
            claim = paste0(experience, ", ",
                           recode(cell, n_nonpartisan = "nonpartisan N",
                                  pct_nonpartisan = "nonpartisan %",
                                  n_partisan = "partisan N",
                                  pct_partisan = "partisan %")),
            value_rewrite,
            notes = "")

inexperienced <- filter(table_1, experience == "No previous political experience")
experience_gap <- inexperienced$pct_partisan - inexperienced$pct_nonpartisan

f3_pol_np <- drawn(f3, panel == "Nonpartisan", coef_group == "Pol. Experience")
f3_pol_diff <- drawn(f3, panel == "Difference", coef_group == "Pol. Experience")

scalar_rows <- tribble(
  ~claim_id, ~table_figure, ~claim, ~value_rewrite, ~notes,

  "intro_experience_gap_pp", "Figure 3",
  "Introduction: political experience effect, nonpartisan minus partisan (pp)",
  100 * mean(f3_pol_diff$estimate), "",

  "obs_n_elections", "Observational text",
  "Mayoral elections in the dataset", dataset$n_elections, "",

  "obs_year_first", "Observational text",
  "First election year", dataset$year_first, "",

  "obs_year_last", "Observational text",
  "Last election year", dataset$year_last, "",

  "obs_n_municipalities", "Observational text",
  "Distinct municipalities", dataset$n_municipalities,
  paste0("Does not reproduce. The recovered file holds ", dataset$n_municipalities,
         " distinct FIPS place codes across its ", dataset$n_elections,
         " elections, and no other reading of it returns 225: municipalities with more ",
         "than one election give 171, the contested subset gives 216 and the five-digit ",
         "prefix gives 213. The dataset reproduces the article's election count and year ",
         "range exactly, so it is the file the article describes"),

  "table_1_chisq_statistic", "Table 1",
  "Chi-squared statistic", chisq$statistic, "",

  "table_1_chisq_p_value", "Table 1",
  "Chi-squared p-value", chisq$p_simulated_median,
  paste0("The archive calls chisq.test(simulate.p.value = TRUE) and sets no seed, so ",
         "the published value is one draw rather than a fixed quantity. Over 500 ",
         "replications the p-value runs from ", signif(chisq$p_simulated_min, 2), " to ",
         signif(chisq$p_simulated_max, 2), ", ",
         round(100 * chisq$share_rounding_to_0.002),
         " per cent of draws round to the published 0.002, and the asymptotic p-value ",
         "is ", signif(chisq$p_asymptotic, 3), ". Compared against that distribution ",
         "rather than against one draw, the published value reproduces"),

  "obs_partisan_no_experience_pct", "Observational text",
  "Partisan elections, winners with no previous political experience (%)",
  inexperienced$pct_partisan, "",

  "obs_nonpartisan_no_experience_pct", "Observational text",
  "Nonpartisan elections, winners with no previous political experience (%)",
  inexperienced$pct_nonpartisan, "",

  "obs_experience_gap_pp", "Observational text",
  "Partisan minus nonpartisan, inexperienced winners (pp)", experience_gap, "",

  "obs_experience_gap_pp_restated", "Observational text",
  "Partisan minus nonpartisan, inexperienced winners, restated (pp)", experience_gap, "",

  "obs_n_contested_elections", "Observational text",
  "Elections in which the two candidates' experience differs",
  advantage$n_elections_total, "",

  "obs_partisan_more_experienced_wins_pct", "Observational text",
  "Partisan elections, more experienced candidate wins (%)", advantage$pct_partisan,
  paste0("Does not reproduce as labelled. The data give ",
         round(advantage$pct_partisan, 1), " per cent in partisan elections and ",
         round(advantage$pct_nonpartisan, 1),
         " per cent in nonpartisan elections, so the sentence has the two labels the ",
         "wrong way round; swapping them makes both values reproduce"),

  "obs_nonpartisan_more_experienced_wins_pct", "Observational text",
  "Nonpartisan elections, more experienced candidate wins (%)",
  advantage$pct_nonpartisan,
  "See the row above: the two labels are transposed in the published sentence",

  "obs_experience_advantage_p_value", "Observational text",
  "p-value on the partisan/nonpartisan difference", advantage$p_value_hc2,
  paste0("Does not reproduce. HC2 regression gives ", round(advantage$p_value_hc2, 3),
         " and a chi-squared test of the same 2x2 gives ",
         round(advantage$p_value_chisq, 3),
         ". No standard test of this comparison returns 0.791. The stated conclusion of ",
         "no significant difference is unaffected"),

  "design_elections_per_subject", "Design",
  "Elections judged per subject", design_value("mTurk", "elections_per_subject"), "",

  "design_attributes_nonpartisan", "Design",
  "Attributes displayed in a nonpartisan election",
  design_value("mTurk", "attributes_nonpartisan"), "",

  "design_attributes_partisan", "Design",
  "Attributes displayed in a partisan election",
  design_value("mTurk", "attributes_partisan"), "",

  "design_candidates_per_election", "Design",
  "Candidates shown per election", design_value("mTurk", "candidates_per_election"),
  paste0("The modal count. ",
         design_value("mTurk", "elections_not_showing_two_candidates"),
         " MTurk respondent-election pairs depart from it, because three worker ids ",
         "appear more than once in the deposited file"),

  "intro_information_pieces_min", "Design",
  "Introduction: attributes displayed in a nonpartisan election",
  design_value("mTurk", "attributes_nonpartisan"), "",

  "intro_information_pieces_max", "Design",
  "Introduction: attributes displayed in a partisan election",
  design_value("mTurk", "attributes_partisan"), "",

  "mechanism_attributes_nonpartisan", "Design",
  "Mechanism section: attributes displayed in a nonpartisan election",
  design_value("YouGov", "attributes_nonpartisan"), "",

  "mechanism_attributes_partisan", "Design",
  "Mechanism section: attributes displayed in a partisan election",
  design_value("YouGov", "attributes_partisan"), "",

  "appendix_b_attributes_nonpartisan", "Design",
  "Appendix B: attributes displayed in a nonpartisan election",
  design_value("mTurk", "attributes_nonpartisan"), "",

  "appendix_b_attributes_partisan", "Design",
  "Appendix B: attributes displayed in a partisan election",
  design_value("mTurk", "attributes_partisan"), "",

  "analysis_competence_scale_min", "Design",
  "Competence scale minimum", design_value("mTurk", "competence_scale_min"), "",

  "analysis_competence_scale_max", "Design",
  "Competence scale maximum", design_value("mTurk", "competence_scale_max"), "",

  "mechanism_competence_scale_min", "Design",
  "Mechanism section: competence scale minimum",
  design_value("YouGov", "competence_scale_min"), "",

  "mechanism_competence_scale_max", "Design",
  "Mechanism section: competence scale maximum",
  design_value("YouGov", "competence_scale_max"), "",

  "appendix_c_competence_scale_min", "Design",
  "Appendix C: competence scale minimum",
  design_value("mTurk", "competence_scale_min"), "",

  "appendix_c_competence_scale_max", "Design",
  "Appendix C: competence scale maximum",
  design_value("mTurk", "competence_scale_max"), "",

  "analysis_ci_level", "Figures 3 to 8, B.1, B.2, C.3, C.4",
  "Confidence interval level implied by the published figures (%)",
  100 * (2 * pnorm(unique(round((f3$conf.high[!is.na(f3$estimate)] -
                                   f3$estimate[!is.na(f3$estimate)]) /
                                  f3$std.error[!is.na(f3$estimate)], 4))) - 1), "",

  "results_pol_exp_range_low", "Figure 3",
  "Political experience, MTurk nonpartisan, smallest effect (pp)",
  100 * min(f3_pol_np$estimate),
  paste0("The text gives the range as 25 to 30 percentage points. The four estimates ",
         "run ", round(100 * min(f3_pol_np$estimate), 1), " (City Council Member) to ",
         round(100 * max(f3_pol_np$estimate), 1),
         " (Mayor), so the published range is tight at both ends"),

  "results_pol_exp_range_high", "Figure 3",
  "Political experience, MTurk nonpartisan, largest effect (pp)",
  100 * max(f3_pol_np$estimate),
  "See the row above: the largest of the four estimates is Mayor",

  "results_pol_exp_gap_pp", "Figure 3",
  "Political experience, nonpartisan minus partisan, mean (pp)",
  100 * mean(f3_pol_diff$estimate),
  paste0("The text says approximately 10 percentage points; the four differences run ",
         round(100 * min(f3_pol_diff$estimate), 1), " to ",
         round(100 * max(f3_pol_diff$estimate), 1)),

  "table_a1_n_mturk", "Table A.1",
  "MTurk respondents", table_a1$n_respondents[table_a1$sample == "mTurk"][1], "",

  "table_a1_n_yougov", "Table A.1",
  "YouGov respondents", table_a1$n_respondents[table_a1$sample == "YouGov"][1], "",

  "appendix_title_year_first", "Observational text",
  "Appendix title: first election year", dataset$year_first, "",

  "appendix_title_year_last", "Observational text",
  "Appendix title: last election year", dataset$year_last, "",

  "discussion_correlation", "Discussion",
  "Correlation of the MTurk and YouGov effect estimates",
  correlation$correlation[correlation$method == "pearson" &
                            correlation$specification == "archive (YouGov unweighted)"],
  paste0("Reproduces only on the archive's unweighted YouGov fits. Weighting them, as ",
         "the YouGov main-effects figure does, gives ",
         round(correlation$correlation[correlation$method == "pearson" &
                                         correlation$specification == "YouGov weighted"], 4))
)

age_rows <- design |>
  filter(sample == "mTurk", str_detect(parameter, "^age_level_")) |>
  transmute(claim_id = paste0("table_2_age_", value),
            table_figure = "Table 2",
            claim = paste0("Age attribute level ", str_remove(parameter, "age_level_")),
            value_rewrite = value,
            notes = "")

table_a1_party_rows <- table_a1 |>
  transmute(claim_id = paste0("table_a1_party_", str_to_lower(sample), "_",
                              str_to_lower(party_id)),
            table_figure = "Table A.1",
            claim = paste0(sample, " ", party_id, " share"),
            value_rewrite = proportion,
            notes = "")

# Numeric claims the deposit cannot reach ----
# The remaining panels of Table A.1 report respondent race, gender, ideology, education
# and age, and neither deposited data file carries a respondent variable beyond party
# identification. The two career shares beneath Table 1 need a candidate occupation the
# recovered observational file does not record. The footnote's two comparisons are
# against estimators the deposit never fits.
table_a1_absent_rows <- published_claims |>
  filter(location == "Table A.1", claim_type == "pipeline",
         !str_detect(claim_id, "^table_a1_(party|n)_")) |>
  transmute(claim_id,
            table_figure = "Table A.1",
            claim = paste0("Respondent ", str_replace(claim_id, "^table_a1_([a-z]+)_.*$", "\\1"),
                           " panel: ", str_remove(claim_id, "^table_a1_[a-z]+_")),
            value_rewrite = NA_real_,
            notes = paste0("No counterpart in the deposit: the deposited data files carry ",
                           "no respondent variable beyond party identification, so ",
                           "40 of the table's 48 published cells cannot be rebuilt at all"))

male_dem <- bind_rows(mutate(drawn(f5, coef_group == "Gender", party == "Democrats",
                                   panel != "Difference"), sample = "MTurk"),
                      mutate(drawn(f6, coef_group == "Gender", party == "Democrats",
                                   panel != "Difference"), sample = "YouGov"))

absent_rows <- tribble(
  ~claim_id, ~table_figure, ~claim, ~notes,
  "results_democrats_female_preference_pp", "Figures 5 and 6",
  "Democrat preference for a female over a male candidate (pp)",
  paste0("The sentence names neither a sample nor an election type, so no single ",
         "estimate is the one it reports. The four it could mean are ",
         paste0(male_dem$sample, " ", male_dem$panel, " ",
                round(-100 * male_dem$estimate, 1), collapse = ", "),
         ". None is 10 and the closest rounds to ",
         round(-100 * min(male_dem$estimate)), "."),
  "obs_partisan_attorney_exec_pct", "Observational text",
  "Partisan elections, attorneys or business executives (%)",
  paste0("No counterpart: the recovered observational file records no candidate career. ",
         "Its ", dataset$n_variables, " variables are ", dataset$variables),
  "obs_nonpartisan_attorney_exec_pct", "Observational text",
  "Nonpartisan elections, attorneys or business executives (%)",
  "No counterpart: see the row above",
  "analysis_amce_decimal_agreement", "Analysis, footnote 5",
  "Agreement between the OLS and cjoint AMCE estimates",
  paste0("No counterpart: the deposit fits no AMCE estimator anywhere, so the ",
         "comparison the footnote reports was never archived"),
  "analysis_logit_agreement", "Analysis, footnote 5",
  "Agreement between the OLS and logit marginal effects",
  "No counterpart: the deposit fits no binary choice model anywhere"
) |>
  mutate(value_rewrite = NA_real_)

# Descriptive claims ----
# A claim about shape, sign, count or ordering gets a computed truth value against the
# study-level estimates rather than a number. Claims whose wording sets no threshold
# ("muted", "similar", "not much") get no verdict, because a verdict would invent one.

f3_np <- drawn(f3, panel == "Nonpartisan")
f3_other_np <- filter(f3_np, coef_group != "Pol. Experience")
f4_np <- drawn(f4, panel == "Nonpartisan")
f4_pol_np <- filter(f4_np, coef_group == "Pol. Experience")
f4_pol_diff <- drawn(f4, panel == "Difference", coef_group == "Pol. Experience")
f5_pol_diff <- drawn(f5, panel == "Difference", coef_group == "Pol. Experience")
f6_pol_diff <- drawn(f6, panel == "Difference", coef_group == "Pol. Experience")
f6_job_diff <- drawn(f6, panel == "Difference", coef_group == "Job Experience")
f7_pol_diff <- drawn(f7, panel == "Difference", coef_group == "Pol. Experience")
fb1_pol_diff <- drawn(fb1, panel == "Difference", coef_group == "Pol. Experience")
fb2_pol_diff <- drawn(fb2, panel == "Difference", coef_group == "Pol. Experience")

outparty_estimates <- c(
  drawn(f5, panel == "Partisan", party == "Democrats", label == "Republican")$estimate,
  drawn(f5, panel == "Partisan", party == "Republicans", label == "Democrat")$estimate,
  drawn(f6, panel == "Partisan", party == "Democrats", label == "Republican")$estimate,
  drawn(f6, panel == "Partisan", party == "Republicans", label == "Democrat")$estimate)
inparty_estimates <- c(
  drawn(f5, panel == "Partisan", party == "Democrats", label == "Democrat")$estimate,
  drawn(f5, panel == "Partisan", party == "Republicans", label == "Republican")$estimate,
  drawn(f6, panel == "Partisan", party == "Democrats", label == "Democrat")$estimate,
  drawn(f6, panel == "Partisan", party == "Republicans", label == "Republican")$estimate)

race_np_56 <- bind_rows(drawn(f5, panel == "Nonpartisan", coef_group == "Race"),
                        drawn(f6, panel == "Nonpartisan", coef_group == "Race"))
pol_56 <- bind_rows(drawn(f5, coef_group == "Pol. Experience", panel != "Difference"),
                    drawn(f6, coef_group == "Pol. Experience", panel != "Difference"))
pol_78 <- bind_rows(drawn(f7, coef_group == "Pol. Experience", panel != "Difference"),
                    drawn(f8, coef_group == "Pol. Experience", panel != "Difference"))
race_78 <- bind_rows(mutate(drawn(f7, coef_group == "Race", panel != "Difference"),
                            sample = "MTurk"),
                     mutate(drawn(f8, coef_group == "Race", panel != "Difference"),
                            sample = "YouGov"))
trio_78 <- bind_rows(
  drawn(f7, panel == "Nonpartisan",
        label %in% c("Police Officer", "Small Business Owner", "Business Executive")),
  drawn(f8, panel == "Nonpartisan",
        label %in% c("Police Officer", "Small Business Owner", "Business Executive")))
male_rep <- bind_rows(drawn(f5, coef_group == "Gender", party == "Republicans",
                            panel != "Difference"),
                      drawn(f6, coef_group == "Gender", party == "Republicans",
                            panel != "Difference"))
policy_business <- drawn(policy, panel == "Nonpartisan",
                         label %in% c("Small Business Owner", "Business Executive"))
policy_pol_dem <- drawn(policy, panel == "Nonpartisan", party == "Democrats",
                        coef_group == "Pol. Experience")

mean_by <- function(df, sample_label, party_label) {
  mean(df$estimate[df$sample == sample_label & df$party == party_label])
}

descriptive_rows <- tribble(
  ~claim_id, ~claim, ~holds,

  "desc_chisq_significant",
  "Table 1: the chi-squared test is statistically significant",
  as.numeric(chisq$p_asymptotic < 0.05 & chisq$p_simulated_max < 0.05),

  "desc_nonpartisan_winners_more_experienced",
  "Fewer nonpartisan than partisan winners lack political experience",
  as.numeric(inexperienced$pct_nonpartisan < inexperienced$pct_partisan),

  "desc_experience_advantage_not_significant",
  "The partisan/nonpartisan difference in the experience advantage is not significant",
  as.numeric(advantage$p_value_hc2 >= 0.05),

  "desc_mturk_sample_differences",
  "The MTurk sample is whiter, more male, more liberal, more Democratic, better educated and younger",
  NA_real_,

  "desc_strongest_effects_pol_experience",
  "Figure 3: every political experience effect exceeds every other effect in magnitude",
  as.numeric(min(abs(f3_pol_np$estimate)) > max(abs(f3_other_np$estimate))),

  "desc_mayor_rewarded_most",
  "Figure 3: Mayor is the largest political experience effect",
  as.numeric(f3_pol_np$label[which.max(f3_pol_np$estimate)] == "Mayor"),

  "desc_muted_job_race_age_gender",
  "Figure 3: the job experience, race, age and gender effects are relatively muted",
  NA_real_,

  "desc_prefer_female_and_nonwhite",
  "Figure 3: the male effect is negative and every nonwhite effect is positive",
  as.numeric(drawn(f3_np, label == "Male")$estimate < 0 &
               all(filter(f3_np, coef_group == "Race")$estimate > 0)),

  "desc_age_nonmonotonic",
  "Figure 3: the 45-year-old effect is the largest of the age levels and is positive",
  as.numeric(with(filter(f3_np, coef_group == "Age"),
                  label[which.max(estimate)] == "45" & max(estimate) > 0)),

  "desc_partisan_pol_exp_more_muted",
  "Figure 3: every political experience effect is smaller in the partisan panel",
  as.numeric(all(drawn(f3, panel == "Partisan", coef_group == "Pol. Experience")$estimate <
                   f3_pol_np$estimate[match(drawn(f3, panel == "Partisan",
                                                  coef_group == "Pol. Experience")$label,
                                            f3_pol_np$label)])),

  "desc_prefers_independents",
  "Figure 3: both partisan candidate effects are negative against an independent",
  as.numeric(all(drawn(f3, panel == "Partisan", coef_group == "Party")$estimate < 0)),

  "desc_difference_null_job_race_age_gender",
  "Figure 3: no job experience, race, age or gender difference interval excludes zero",
  as.numeric(clear_of_zero(drawn(f3, panel == "Difference",
                                 coef_group != "Pol. Experience")) == 0),

  "desc_difference_significant_pol_experience",
  "Figure 3: every political experience difference interval excludes zero",
  as.numeric(clear_of_zero(f3_pol_diff) == nrow(f3_pol_diff)),

  "desc_yougov_similar_pattern",
  "Figure 4: every political experience effect exceeds every other effect in magnitude",
  as.numeric(min(abs(f4_pol_np$estimate)) >
               max(abs(filter(f4_np, coef_group != "Pol. Experience")$estimate))),

  "desc_school_board_ordering",
  "Figure 4: School Board President is above zero and below every higher office",
  as.numeric(with(f4_pol_np,
                  estimate[label == "School Board President"] > 0 &
                    all(estimate[label != "School Board President"] >
                          estimate[label == "School Board President"]))),

  "desc_yougov_pol_exp_interaction",
  "Figure 4: every political experience difference is positive",
  as.numeric(all(f4_pol_diff$estimate > 0)),

  "desc_stayathome_electrician_negative",
  "Figure 4: both added career levels are negative in both election types",
  as.numeric(all(drawn(f4, panel != "Difference",
                       label %in% c("Stay-at-Home Dad/Mom", "Electrician"))$estimate < 0)),

  "desc_yougov_small_gender_age",
  "Figure 4: the gender and age effects are as small as in the MTurk sample",
  NA_real_,

  "desc_partisans_dislike_outparty_candidates",
  "Figures 5 and 6: every out-party candidate effect is negative",
  as.numeric(all(outparty_estimates < 0)),

  "desc_dislike_outparty_more_than_like_inparty",
  "Figures 5 and 6: out-party dislike exceeds in-party liking in every cell",
  as.numeric(all(abs(outparty_estimates) > abs(inparty_estimates))),

  "desc_race_preference_by_respondent_party",
  "Figures 5 and 6: the nonwhite effects are positive for Democrats and negative for Republicans",
  as.numeric(all(race_np_56$estimate[race_np_56$party == "Democrats"] > 0) &
               all(race_np_56$estimate[race_np_56$party == "Republicans"] < 0)),

  "desc_republicans_no_gender_preference",
  "Figures 5 and 6: no Republican gender interval excludes zero",
  as.numeric(clear_of_zero(male_rep) == 0),

  "desc_race_gender_patterns_stable_across_election_type",
  "Figure 5: the race and gender patterns do not differ much by election type",
  NA_real_,

  "desc_both_parties_reward_experience",
  "Figures 5 and 6: every political experience estimate is positive for both parties",
  as.numeric(all(pol_56$estimate > 0)),

  "desc_prediction_only_among_democrats",
  "Figure 5: the political experience differences clear zero for Democrats and not for Republicans",
  as.numeric(clear_of_zero(filter(f5_pol_diff, party == "Democrats")) ==
               sum(f5_pol_diff$party == "Democrats") &
               clear_of_zero(filter(f5_pol_diff, party == "Republicans")) == 0),

  "desc_clearest_in_mturk",
  "The Democrat minus Republican gap in the political experience difference is larger on MTurk",
  as.numeric(mean(f5_pol_diff$estimate[f5_pol_diff$party == "Democrats"]) -
               mean(f5_pol_diff$estimate[f5_pol_diff$party == "Republicans"]) >
               mean(f6_pol_diff$estimate[f6_pol_diff$party == "Democrats"]) -
               mean(f6_pol_diff$estimate[f6_pol_diff$party == "Republicans"])),

  "desc_yougov_republicans_occupation_democrats_political",
  "Figure 6: the job experience differences run larger for Republicans and the political experience differences larger for Democrats",
  as.numeric(mean(f6_job_diff$estimate[f6_job_diff$party == "Republicans"]) >
               mean(f6_job_diff$estimate[f6_job_diff$party == "Democrats"]) &
               mean(f6_pol_diff$estimate[f6_pol_diff$party == "Democrats"]) >
               mean(f6_pol_diff$estimate[f6_pol_diff$party == "Republicans"])),

  "desc_both_parties_competence_experience",
  "Figures 7 and 8: every political experience competence estimate is positive for both parties",
  as.numeric(all(pol_78$estimate > 0)),

  "desc_democrats_competence_gap_nonpartisan",
  "Figure 7: the competence differences clear zero for Democrats and not for Republicans",
  as.numeric(clear_of_zero(filter(f7_pol_diff, party == "Democrats")) > 0 &
               clear_of_zero(filter(f7_pol_diff, party == "Republicans")) == 0),

  "desc_small_race_gender_age_competence",
  "Figures 7 and 8: the race, gender and age effects on competence are small",
  NA_real_,

  "desc_republicans_white_more_competent",
  "Figures 7 and 8: the mean nonwhite competence effect is negative for Republicans and positive for Democrats in both samples",
  as.numeric(mean_by(race_78, "MTurk", "Republicans") < 0 &
               mean_by(race_78, "YouGov", "Republicans") < 0 &
               mean_by(race_78, "MTurk", "Democrats") > 0 &
               mean_by(race_78, "YouGov", "Democrats") > 0),

  "desc_occupation_competence_by_party",
  "Figures 7 and 8: police officers, small business owners and business executives are rated above educators by Republicans and below by Democrats",
  as.numeric(all(trio_78$estimate[trio_78$party == "Republicans"] > 0) &
               all(trio_78$estimate[trio_78$party == "Democrats"] < 0)),

  "desc_stayathome_not_more_competent",
  "Figure 8: no stay-at-home parent competence effect is above zero",
  as.numeric(all(drawn(f8, label == "Stay-at-Home Dad/Mom",
                       panel != "Difference")$estimate <= 0)),

  "desc_competent_types_elected_nonpartisan",
  "The candidate types rated most competent are the ones preferred in nonpartisan elections",
  NA_real_,

  "desc_policy_index_business_conservative",
  "Both business levels move the policy index in the conservative direction for both parties in both samples",
  as.numeric(all(policy_business$estimate > 0)),

  "desc_policy_index_democrats_experience",
  "No political experience level moves the policy index significantly in the liberal direction for Democrat respondents",
  as.numeric(sum(policy_pol_dem$conf.high < 0) == 0),

  "desc_satisficing_mturk_same_party",
  "Figure B.1: every political experience interaction is positive",
  as.numeric(all(fb1_pol_diff$estimate > 0)),

  "desc_pol_exp_effect_larger_nonpartisan",
  "Figures 3 and 4: at least one political experience difference excludes zero in each sample",
  as.numeric(clear_of_zero(f3_pol_diff) > 0 & clear_of_zero(f4_pol_diff) > 0),

  "desc_appendix_b_mturk_significant_interaction",
  "Figure B.1: at least one political experience interaction excludes zero",
  as.numeric(clear_of_zero(fb1_pol_diff) > 0),

  "desc_appendix_b_yougov_no_variation",
  "Figure B.2: no political experience interaction excludes zero",
  as.numeric(clear_of_zero(fb2_pol_diff) == 0),

  "desc_appendix_c_results_similar",
  "Appendix C: the competence results resemble the candidate preference results",
  NA_real_
) |>
  mutate(table_figure = "Descriptive", value_rewrite = NA_real_, notes = "")

# Assemble ----

gt <- bind_rows(table_1_rows, scalar_rows, age_rows, table_a1_party_rows,
                table_a1_absent_rows, absent_rows, descriptive_rows) |>
  join_checked(select(published_claims, claim_id, value_paper), by = "claim_id")

stopifnot(!any(is.na(gt$claim_id)), !any(duplicated(gt$claim_id)))

# Agreement at the precision the article prints ----
# value_paper is the string the page carries. A rewrite value agrees when, printed to
# that string's number of decimals, it gives the same digits. A numeric tolerance
# cannot express this, because a double does not record how many decimals were printed.
printed_decimals <- function(target) {
  if_else(str_detect(target, "\\."), nchar(str_remove(target, "^.*\\.")), 0L)
}

agrees <- function(value, target) {
  target_clean <- str_remove_all(target, ",")
  numeric_target <- suppressWarnings(as.numeric(target_clean))
  comparable <- !is.na(value) & !is.na(numeric_target)
  formats <- paste0("%.", printed_decimals(replace_na(target_clean, "0")), "f")
  same <- sprintf(formats, replace_na(value, 0)) ==
    sprintf(formats, replace_na(numeric_target, 0))
  if_else(comparable, as.numeric(same), NA_real_)
}

gt <- gt |>
  mutate(paper_id = "kirkland_coppock_2018",
         value_script = NA_real_,
         match = NA_real_,
         match_rewrite = if_else(table_figure == "Descriptive", holds,
                                 agrees(value_rewrite, value_paper)))

# The chi-squared p-value is a Monte Carlo draw from an unseeded simulation, not a
# fixed quantity, so agreement at printed precision is the wrong test for it. The
# published 0.002 sits inside the range the archive's own procedure produces and is
# reached by roughly a quarter of draws, so it reproduces.
gt$match_rewrite[gt$claim_id == "table_1_chisq_p_value"] <- 1

# Where the fault lies on every row that does not reproduce ----
# A match_rewrite of 0 otherwise reads as a failure of the rewrite, which it almost
# never is. Rows that could not be evaluated at all carry a locus too, because a claim
# the deposit cannot support is a finding rather than a blank.
gt <- gt |>
  mutate(defect_locus = case_when(
    match_rewrite == 0 ~ "paper_internal",
    is.na(match_rewrite) & is.na(value_rewrite) & table_figure != "Descriptive" ~ "archive",
    .default = NA_character_
  ))

# The three descriptive claims with no verdict are unevaluated for a reason in the
# wording, not a defect anywhere, except the sample-comparison sentence, whose five
# unevaluable dimensions are unevaluable because the deposit does not carry them.
gt$defect_locus[gt$claim_id == "desc_mturk_sample_differences"] <- "archive"

# The gender sentence is unevaluable for a third reason: the pipeline produces four
# estimates it could be reporting and the sentence names none of them, so nothing is
# established about whether the published 10 is right.
gt$defect_locus[gt$claim_id == "results_democrats_female_preference_pp"] <- "unresolved"

# A verdict clause computed from the comparison that sets the verdict, so a note and a
# verdict cannot contradict each other.
gt <- gt |>
  mutate(verdict_clause = case_when(
    is.na(match_rewrite) & table_figure == "Descriptive" ~
      "The sentence sets no threshold, so no verdict is computed; see the claim block for the distribution.",
    is.na(match_rewrite) ~ "Not verifiable against the deposit.",
    match_rewrite == 1 & table_figure == "Descriptive" ~ "The description holds.",
    match_rewrite == 1 ~ "Reproduces at the precision the article prints.",
    table_figure == "Descriptive" ~ "The description does not hold.",
    .default = paste0("Does not reproduce: the pipeline gives ",
                      formatC(value_rewrite, format = "fg", digits = 4),
                      " against a published ", value_paper, ".")),
    notes = str_squish(paste(verdict_clause, notes))) |>
  select(paper_id, claim_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, defect_locus, notes)

write_csv(gt, here::here("ground_truth", "kirkland_coppock_2018_ground_truth.csv"))

# Coverage gate ----
# published_claims.csv is the exhaustive extraction and governs coverage for both
# instruments. Every pipeline and descriptive claim must carry a row here and a block
# in maintained/in_text_claims.R.
#
# Matching "# covers:" markers would prove only that a block was written. A block that
# errors, or that prints nothing, satisfies a textual check completely. So the file is
# run non-interactively, its stdout is captured, and the claim ids are read back off
# the CLAIM lines it actually printed. The count of those lines against the count of
# declarations is the check.
claims_file <- read_lines(here::here("maintained", "in_text_claims.R"))

declared_ids <- claims_file |>
  str_subset("^#\\s*covers:") |>
  str_remove("^#\\s*covers:") |>
  str_squish() |>
  str_split(" ") |>
  list_c()

expand_marker <- function(marker) {
  if (!str_detect(marker, "\\*$")) return(marker)
  prefix <- str_remove(marker, "\\*$")
  matched <- published_claims$claim_id[str_starts(published_claims$claim_id, fixed(prefix))]
  stopifnot(length(matched) > 0)
  matched
}

declared_ids <- unique(list_c(map(declared_ids, expand_marker)))

claims_output <- system2("Rscript", here::here("maintained", "in_text_claims.R"),
                         stdout = TRUE, stderr = FALSE)

printed_ids <- claims_output |>
  str_subset("^CLAIM ") |>
  str_remove("^CLAIM ") |>
  str_remove(" \\|.*$") |>
  str_squish()

must_be_covered <- published_claims$claim_id[published_claims$claim_type %in%
                                               c("pipeline", "descriptive")]

missing_blocks <- setdiff(must_be_covered, printed_ids)
unknown_ids <- setdiff(printed_ids, published_claims$claim_id)
declared_not_printed <- setdiff(declared_ids, printed_ids)
printed_not_declared <- setdiff(printed_ids, declared_ids)
missing_gt_rows <- setdiff(must_be_covered, gt$claim_id)

if (length(missing_blocks) > 0) {
  stop("published claims with no block in maintained/in_text_claims.R: ",
       paste(missing_blocks, collapse = ", "))
}
if (length(unknown_ids) > 0) {
  stop("maintained/in_text_claims.R prints claim ids the article does not make: ",
       paste(unknown_ids, collapse = ", "))
}
if (length(declared_not_printed) > 0) {
  stop("blocks declare a claim they do not print: ",
       paste(declared_not_printed, collapse = ", "))
}
if (length(printed_not_declared) > 0) {
  stop("blocks print a claim they do not declare: ",
       paste(printed_not_declared, collapse = ", "))
}
if (length(missing_gt_rows) > 0) {
  stop("published claims with no ground truth row: ",
       paste(missing_gt_rows, collapse = ", "))
}
stopifnot(length(printed_ids) == length(unique(printed_ids)),
          length(printed_ids) == length(declared_ids),
          all(gt$claim_id %in% published_claims$claim_id))

print(gt |> select(claim_id, claim, value_rewrite, value_paper, match_rewrite, defect_locus),
      n = nrow(gt), width = 200)
print(count(published_claims, claim_type), width = 200)
print(count(gt, table_figure, match_rewrite), n = 100, width = 200)
