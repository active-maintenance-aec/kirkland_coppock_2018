# kirkland_coppock_2018/maintained/in_text_claims.R
# Output: printed to the console; no file
# Depends on: helpers.R, ground_truth/published_claims.csv,
#             output/table_1_observational_experience.csv,
#             output/table_a1_party_identification.csv,
#             output/text_observational_chisq.csv,
#             output/text_observational_dataset_description.csv,
#             output/text_observational_experience_advantage.csv,
#             output/text_design_parameters.csv,
#             output/text_mturk_yougov_correlation.csv,
#             output/text_policy_index_het_fx.csv,
#             output/figure_*.csv
# Description: Every number the article and the online appendix print, paired with the
#   sentence that prints it and with the value this pipeline produces, in the article's
#   own units and rounding, in the order a reader meets them.
#
#   This file recomputes. It reads the same output/ files the ground truth reads and
#   does its own filtering, unit conversion and rounding, so the two arrive at each
#   number by separate paths and a disagreement between them is a finding rather than
#   a coincidence. It never reads the ground-truth CSV, and it never fits a model: the
#   pipeline has already produced the estimates, and everything here is a derivation
#   from them.
#
#   Each block carries the article's sentence verbatim, then the call that prints the
#   claim. The claim id is the first argument of that call and is printed on the line
#   the call emits: "CLAIM <id> = <value> || <label>". That printed line is the link
#   to ground_truth/published_claims.csv, and it is the only link.
#   ground_truth/build_ground_truth.R runs this file non-interactively, reads the ids
#   back off the lines it actually printed, and halts unless they cover every pipeline
#   and descriptive row of the extraction and name nothing the article does not claim.
#   Nothing is read out of a comment: a comment naming a claim id would be a second
#   copy of the link that could go stale on its own, which is what a gate reading the
#   program rather than the text exists to avoid.
#
#   Claims classified definitional, structural or transcribed appear here only where
#   the pipeline can reach the quantity. A scale endpoint the data records is read
#   back; an age band in a demographic table the deposit does not carry, a page date
#   and a figure number in another document's numbering are verified at the point of
#   use and have no block.
#
#   cat() is used throughout, which the house style permits in this file alone: a
#   labelled line per claim is what makes the output scannable beside the sentences.

source(here::here("maintained", "helpers.R"))

options(width = 200)

out <- function(f) read_csv(here("maintained", "output", f), show_col_types = FALSE)

# value_paper holds the string the article prints, so the column is read as text. Left
# to guess, readr would turn a column of numeric-looking entries into doubles and drop
# exactly the printed precision the string is there to preserve: 0.150 would come back
# as 0.15 and 1,204 as 1204.
published_claims <- read_csv(here("ground_truth", "published_claims.csv"),
                             col_types = cols(value_paper = col_character(),
                                              .default = col_guess()))

table_1 <- out("table_1_observational_experience.csv")
table_a1 <- out("table_a1_party_identification.csv")
chisq <- out("text_observational_chisq.csv")
dataset <- out("text_observational_dataset_description.csv")
advantage <- out("text_observational_experience_advantage.csv")
design <- out("text_design_parameters.csv")
correlation <- out("text_mturk_yougov_correlation.csv")
policy <- out("text_policy_index_het_fx.csv")

figure_3 <- out("figure_3_mturk_main_candidate_pref.csv")
figure_4 <- out("figure_4_yougov_main_candidate_pref.csv")
figure_5 <- out("figure_5_mturk_het_fx_candidate_pref.csv")
figure_6 <- out("figure_6_yougov_het_fx_candidate_pref.csv")
figure_7 <- out("figure_7_mturk_het_fx_competence.csv")
figure_8 <- out("figure_8_yougov_het_fx_competence.csv")
figure_b1 <- out("figure_b1_mturk_satisficing.csv")
figure_b2 <- out("figure_b2_yougov_satisficing.csv")
figure_c3 <- out("figure_c3_mturk_main_competence.csv")
figure_c4 <- out("figure_c4_yougov_main_competence.csv")

# Reporting ----
# Every claim prints one line in the form "CLAIM <id> = <value> || <label>". The id
# comes first because the coverage gate reads it back, and the label follows the value
# because a reader scanning the output is looking for the number. Evidence lines are
# indented and carry no id, so a claim whose evidence runs to several values still
# counts once.
report_value <- function(claim_id, label, value, digits = 1) {
  stopifnot(length(value) == 1, !is.na(value))
  cat("CLAIM ", claim_id, " = ", formatC(value, digits = digits, format = "f"),
      " || ", label, "\n", sep = "")
}

report_text <- function(claim_id, label, value) {
  stopifnot(length(value) == 1, !is.na(value))
  cat("CLAIM ", claim_id, " = ", value, " || ", label, "\n", sep = "")
}

evidence <- function(text) cat("    evidence: ", text, "\n", sep = "")

# Accessors ----
# Each stops when its filter does not select exactly one row, so a claim cannot
# quietly read a row that is not there or average two that are.
one <- function(df, column, ...) {
  hit <- filter(df, ...)
  stopifnot(nrow(hit) == 1, !is.na(hit[[column]]))
  hit[[column]]
}

design_value <- function(sample_label, parameter_name) {
  one(design, "value", sample == sample_label, parameter == parameter_name)
}

# Rows of a figure's estimates, with the base-category placeholders dropped.
estimates <- function(df, ...) {
  hit <- filter(df, ..., !is.na(estimate))
  stopifnot(nrow(hit) > 0)
  hit
}

# A labelled list of estimates, which is what a descriptive claim needs printed:
# the individual values, not a summary of them.
estimate_list <- function(df, digits = 3, scale = 1, name = NULL) {
  labels <- if (is.null(name)) as.character(df$label) else name
  paste0(labels, " = ", formatC(scale * df$estimate, digits = digits, format = "f"),
         collapse = "; ")
}

excludes_zero <- function(df) df$conf.low > 0 | df$conf.high < 0

# The published figures draw estimate +/- a fixed normal multiplier, so the interval
# level is recoverable from any of them.
interval_multiplier <- function(df) {
  rows <- filter(df, !is.na(estimate))
  multipliers <- round((rows$conf.high - rows$estimate) / rows$std.error, 4)
  stopifnot(n_distinct(multipliers) == 1)
  multipliers[1]
}

# Introduction ----

# "To preview our results, we see a clear difference across electoral institutions in
# how subjects use information about candidate experience in both samples. In
# nonpartisan elections, we find that the effect of candidate experience on vote
# choice is approximately 10 percentage points higher than in partisan elections."
intro_gap <- estimates(figure_3, panel == "Difference", coef_group == "Pol. Experience")
report_value("intro_experience_gap_pp",
             "Introduction, political experience effect, nonpartisan minus partisan (pp)",
             100 * mean(intro_gap$estimate))
evidence(estimate_list(intro_gap, digits = 1, scale = 100))

# "Our survey respondents have to choose between two hypothetical candidates on the
# basis of the five or six pieces of information we provide."
report_value("intro_information_pieces_min",
             "Introduction, attributes displayed in a nonpartisan election (MTurk)",
             design_value("mTurk", "attributes_nonpartisan"), digits = 0)
report_value("intro_information_pieces_max",
             "Introduction, attributes displayed in a partisan election (MTurk)",
             design_value("mTurk", "attributes_partisan"), digits = 0)

# The introduction's remaining numeral is the turn of the 20th century, a fact about
# the Progressive era taken from Welch and Bledsoe (1988). It is classified
# transcribed in published_claims.csv and has no block, as do the correlations of
# 0.88 to 0.99 that the theory section quotes from Lim and Snyder (2015).

# Observational evidence ----

# "A first glance at this prediction comes from the historical record of 1010 US
# mayoral elections held between 1945 and 2007. This dataset covers 225 unique
# municipalities and records background characteristics of winners and runners-up,
# contextual information such as electoral rules, and electoral outcomes."
report_value("obs_n_elections", "Observational dataset, mayoral elections",
             dataset$n_elections, digits = 0)
report_value("obs_year_first", "Observational dataset, first election year",
             dataset$year_first, digits = 0)
report_value("obs_year_last", "Observational dataset, last election year",
             dataset$year_last, digits = 0)
report_value("obs_n_municipalities", "Observational dataset, distinct municipalities",
             dataset$n_municipalities, digits = 0)
evidence(paste0("distinct FIPS place codes across the ",
                dataset$n_elections, " elections; the article states 225"))

# Table 1, political experience of the winning candidate in partisan and nonpartisan
# US mayoral elections, as this pipeline rebuilds it from the recovered data. Cells
# are read out one at a time so each carries its own claim id.
table_1_slugs <- c(
  "No previous political experience" = "no_previous_political_experience",
  "City legislator" = "city_legislator",
  "County legislator" = "county_legislator",
  "State legislator" = "state_legislator",
  "US legislator" = "us_legislator",
  "Mayor" = "mayor",
  "Total" = "total"
)

table_1_long <- table_1 |>
  pivot_longer(-experience, names_to = "cell", values_to = "value") |>
  mutate(claim_id = paste0("table_1_", table_1_slugs[experience], "_", cell),
         label = paste0("Table 1, ", experience, ", ",
                        recode(cell, n_nonpartisan = "nonpartisan N",
                               pct_nonpartisan = "nonpartisan %",
                               n_partisan = "partisan N",
                               pct_partisan = "partisan %")))

walk2(table_1_long$claim_id, seq_len(nrow(table_1_long)),
      \(id, i) report_value(id, table_1_long$label[i], table_1_long$value[i], digits = 0))

# The chi-squared test printed beneath Table 1.
report_value("table_1_chisq_statistic", "Table 1, chi-squared statistic",
             chisq$statistic)

# The archive calls chisq.test(simulate.p.value = TRUE) and sets no seed, so the
# published 0.002 is one draw from a distribution rather than a fixed quantity. The
# median of 500 replications is printed, with the full range as evidence.
report_value("table_1_chisq_p_value",
             "Table 1, chi-squared p-value, median of 500 simulations",
             chisq$p_simulated_median, digits = 3)
evidence(paste0("simulated p runs ", signif(chisq$p_simulated_min, 2), " to ",
                signif(chisq$p_simulated_max, 2), "; ",
                round(100 * chisq$share_rounding_to_0.002),
                " per cent of draws round to 0.002; asymptotic p is ",
                signif(chisq$p_asymptotic, 3)))

# "The statistically significant v2 statistic indicates that the political experience
# of winning candidates differs across partisan and nonpartisan elections."
report_text("desc_chisq_significant",
            "Table 1, is the chi-squared test significant at the 0.05 level",
            if_else(chisq$p_asymptotic < 0.05 & chisq$p_simulated_max < 0.05,
                    "yes", "no"))
evidence(paste0("asymptotic p = ", signif(chisq$p_asymptotic, 3),
                "; every one of 500 simulated draws is below ",
                signif(chisq$p_simulated_max, 2)))

# "In partisan elections, 30% of winning candidates have no previous political
# experience whereas in nonpartisan elections, the share of inexperienced winning
# candidates drops by 9 percentage points to 21%."
inexperienced <- filter(table_1, experience == "No previous political experience")
report_value("obs_partisan_no_experience_pct",
             "Partisan elections, winners with no previous political experience (%)",
             inexperienced$pct_partisan, digits = 0)
report_value("obs_nonpartisan_no_experience_pct",
             "Nonpartisan elections, winners with no previous political experience (%)",
             inexperienced$pct_nonpartisan, digits = 0)
report_value("obs_experience_gap_pp",
             "Partisan minus nonpartisan, inexperienced winners (pp)",
             inexperienced$pct_partisan - inexperienced$pct_nonpartisan, digits = 0)

# "The 9 percentage point difference might reflect the effect of nonpartisan ballots
# on who gets elected, but it could just as easily reflect other differences between
# cities that do and do not hold partisan elections."
report_value("obs_experience_gap_pp_restated",
             "Partisan minus nonpartisan, inexperienced winners, restated (pp)",
             inexperienced$pct_partisan - inexperienced$pct_nonpartisan, digits = 0)

# "That fewer inexperienced candidates win in nonpartisan elections fits with our
# predictions." and, later, "While we do see that winners in nonpartisan elections
# appear to have more political experience than winners in partisan elections, an
# alternative analysis of the historical record paints a murkier picture."
report_text("desc_nonpartisan_winners_more_experienced",
            "Do fewer nonpartisan winners lack political experience",
            if_else(inexperienced$pct_nonpartisan < inexperienced$pct_partisan,
                    "yes", "no"))
evidence(paste0("nonpartisan ", inexperienced$pct_nonpartisan, " per cent against partisan ",
                inexperienced$pct_partisan, " per cent inexperienced; the share holding ",
                "any prior office is ", 100 - inexperienced$pct_nonpartisan, " against ",
                100 - inexperienced$pct_partisan))

# "In partisan elections, 63% of candidates are attorneys or business executives while
# in nonpartisan elections the corresponding figure is 48%."
# The recovered observational file records no candidate career at all, so neither
# share has a counterpart anywhere in the pipeline. The variables it does carry are
# printed instead, which is what makes the absence checkable rather than asserted.
career_variables <- str_subset(str_split_1(dataset$variables, "; "),
                               regex("occupation|career|job|attorney|business|profession",
                                     ignore_case = TRUE))
report_text("obs_partisan_attorney_exec_pct",
            "Partisan elections, attorneys or business executives (%)",
            "no counterpart: the recovered data record no candidate career")
report_text("obs_nonpartisan_attorney_exec_pct",
            "Nonpartisan elections, attorneys or business executives (%)",
            "no counterpart: the recovered data record no candidate career")
evidence(paste0(dataset$n_variables, " variables, ", length(career_variables),
                " of them naming an occupation: ", dataset$variables))

# "Subsetting our dataset to only those elections in which candidates have different
# levels of political experience (779 elections), we see that the candidate with more
# experience wins about 62% of the time in partisan elections and 61% of the time in
# nonpartisan elections. This difference is not statistically significant (p = 0.791)."
report_value("obs_n_contested_elections",
             "Elections in which the two candidates' experience differs",
             advantage$n_elections_total, digits = 0)

report_value("obs_partisan_more_experienced_wins_pct",
             "Partisan elections, more experienced candidate wins (%)",
             advantage$pct_partisan, digits = 0)

report_value("obs_nonpartisan_more_experienced_wins_pct",
             "Nonpartisan elections, more experienced candidate wins (%)",
             advantage$pct_nonpartisan, digits = 0)
evidence(paste0("at one decimal, partisan ", round(advantage$pct_partisan, 1),
                " and nonpartisan ", round(advantage$pct_nonpartisan, 1),
                "; the article assigns 62 to partisan and 61 to nonpartisan"))

report_value("obs_experience_advantage_p_value",
             "p-value on the partisan/nonpartisan difference (HC2 regression)",
             advantage$p_value_hc2, digits = 3)
evidence(paste0("chi-squared on the same 2x2 gives ",
                round(advantage$p_value_chisq, 3),
                "; the article reports 0.791"))

report_text("desc_experience_advantage_not_significant",
            "Is the partisan/nonpartisan difference distinguishable from zero",
            if_else(advantage$p_value_hc2 >= 0.05, "no", "yes"))
evidence(paste0("difference of ", round(advantage$difference_pp, 1),
                " pp, HC2 p = ", round(advantage$p_value_hc2, 3)))

# Conjoint Candidate Choice Survey Experiments ----

# "In our studies, subjects judge five successive elections in which five (or six)
# attributes of two competing candidates are displayed: their race, gender, political
# experience, career experience, age, and in some cases, political party."
report_value("design_elections_per_subject", "Elections judged per subject (MTurk)",
             design_value("mTurk", "elections_per_subject"), digits = 0)
report_value("design_attributes_nonpartisan",
             "Attributes displayed in a nonpartisan election (MTurk)",
             design_value("mTurk", "attributes_nonpartisan"), digits = 0)
report_value("design_attributes_partisan",
             "Attributes displayed in a partisan election (MTurk)",
             design_value("mTurk", "attributes_partisan"), digits = 0)
report_value("design_candidates_per_election", "Candidates shown per election (MTurk)",
             design_value("mTurk", "candidates_per_election"), digits = 0)
evidence(paste0("the modal count; ",
                design_value("mTurk", "elections_not_showing_two_candidates"),
                " of the MTurk respondent-election pairs depart from it, because three ",
                "worker ids appear more than once in the deposited file"))

# The stated limit of six or seven attributes is the methodological consensus the
# design section cites, not a property of this experiment, so it is classified
# transcribed and has no block.

# "The possible levels of each attribute are displayed in Table 2."
walk(1:4, \(i) report_value(paste0("table_2_age_",
                                   design_value("mTurk", paste0("age_level_", i))),
                            paste0("Table 2, age attribute level ", i),
                            design_value("mTurk", paste0("age_level_", i)), digits = 0))

# "The demographic profile of the MTurk sample is quite different from that of the
# YouGov sample. On average, the MTurk sample is whiter, more male, more liberal, more
# Democratic, better educated, and younger."
mturk_democrat <- one(table_a1, "proportion", sample == "mTurk", party_id == "Democrat")
yougov_democrat <- one(table_a1, "proportion", sample == "YouGov", party_id == "Democrat")
report_text("desc_mturk_sample_differences",
            "Is the MTurk sample more Democratic than the YouGov sample",
            if_else(mturk_democrat > yougov_democrat, "yes", "no"))
evidence(paste0("Democrat share ", mturk_democrat, " on MTurk against ", yougov_democrat,
                " on YouGov. The five other dimensions the sentence names (race, gender, ",
                "ideology, education, age) have no counterpart: neither deposited data ",
                "file carries a respondent variable beyond party identification"))

# Analysis ----

# "A second dependent variable, candidate competence, is asked 'On a scale from 0 to
# 100, how competent do you think these candidates would be as mayor?'"
report_value("analysis_competence_scale_min", "Competence scale minimum (MTurk)",
             design_value("mTurk", "competence_scale_min"), digits = 0)
report_value("analysis_competence_scale_max", "Competence scale maximum (MTurk)",
             design_value("mTurk", "competence_scale_max"), digits = 0)

# "For this reason, we will present our results graphically using coefficient plots,
# in which attribute levels are placed on the vertical axis and point estimates with
# 95% confidence intervals are placed on the horizontal axis."
report_value("analysis_ci_level", "Confidence interval level implied by the figures (%)",
             100 * (2 * pnorm(interval_multiplier(figure_3)) - 1))
evidence(paste0("every interval in Figure 3 is the estimate plus or minus ",
                interval_multiplier(figure_3), " standard errors"))

# "Indeed, when we analyze our MTurk experiment using their estimator, both our point
# estimates and standard errors differ only in the third or fourth decimal place. ...
# As it happens, the estimated marginal effects from a logit model correspond almost
# exactly to the OLS estimates and none of our substantive interpretations depend on
# this choice."
# Neither comparison exists in the deposit. Its scripts fit no AMCE estimator and no
# binary choice model, so the footnote reports two calculations that were never
# archived and that nothing here can reproduce.
report_text("analysis_amce_decimal_agreement",
            "Agreement between the OLS and cjoint AMCE estimates",
            "no counterpart: the deposit fits no AMCE estimator")
report_text("analysis_logit_agreement",
            "Agreement between the OLS and logit marginal effects",
            "no counterpart: the deposit fits no binary choice model")

# Results: Figure 3, MTurk main analysis ----

# "Figure 3 presents the results of the MTurk study. In the first column, the estimates
# of Equation 1 are shown. The strongest effects are observed for the political
# experience attribute."
np_3 <- estimates(figure_3, panel == "Nonpartisan")
pol_3 <- filter(np_3, coef_group == "Pol. Experience")
other_3 <- filter(np_3, coef_group != "Pol. Experience")
report_text("desc_strongest_effects_pol_experience",
            "Is every political experience effect larger in magnitude than every other effect (MTurk, nonpartisan)",
            if_else(min(abs(pol_3$estimate)) > max(abs(other_3$estimate)), "yes", "no"))
evidence(paste0("political experience runs ",
                formatC(100 * min(abs(pol_3$estimate)), digits = 1, format = "f"), " to ",
                formatC(100 * max(abs(pol_3$estimate)), digits = 1, format = "f"),
                " pp in magnitude; every other attribute level runs 0.0 to ",
                formatC(100 * max(abs(other_3$estimate)), digits = 1, format = "f"), " pp"))

# "Relative to a candidate with no political experience, respondents prefer candidates
# who are City Council Members, State Legislators, Mayors, or Representatives in
# Congress by a margin of 25-30 percentage points."
report_value("results_pol_exp_range_low",
             "Figure 3, smallest political experience effect, nonpartisan (pp)",
             100 * min(pol_3$estimate))
report_value("results_pol_exp_range_high",
             "Figure 3, largest political experience effect, nonpartisan (pp)",
             100 * max(pol_3$estimate))
evidence(estimate_list(pol_3, digits = 1, scale = 100))

# "Candidates who previously held a mayoral office were rewarded most for their
# political experience."
report_text("desc_mayor_rewarded_most",
            "Is Mayor the largest political experience effect (MTurk, nonpartisan)",
            if_else(pol_3$label[which.max(pol_3$estimate)] == "Mayor", "yes", "no"))
evidence(estimate_list(arrange(pol_3, desc(estimate)), digits = 1, scale = 100))

# "By contrast, we observe relatively muted effects for the job experience, race, age,
# and gender attributes, although our respondents do express a mild preference for
# candidates who are female and nonwhite."
report_value("desc_muted_job_race_age_gender",
             "Figure 3, largest effect outside political experience, nonpartisan (pp)",
             100 * max(abs(other_3$estimate)))
evidence(estimate_list(arrange(other_3, desc(abs(estimate))), digits = 1, scale = 100))

male_3 <- one(np_3, "estimate", label == "Male")
race_3 <- filter(np_3, coef_group == "Race")
report_text("desc_prefer_female_and_nonwhite",
            "Is the male effect negative and every nonwhite effect positive (MTurk, nonpartisan)",
            if_else(male_3 < 0 & all(race_3$estimate > 0), "yes", "no"))
evidence(paste0("Male = ", formatC(100 * male_3, digits = 1, format = "f"), " pp; ",
                estimate_list(race_3, digits = 1, scale = 100),
                " pp, each against a White reference"))

# "Our respondents' preferences for candidates varied non-monotonically with age:
# 45-year-olds are preferred to 35-year-olds and 55- and 65-year olds."
age_3 <- filter(np_3, coef_group == "Age")
report_text("desc_age_nonmonotonic",
            "Is the 45-year-old effect the largest of the age levels (MTurk, nonpartisan)",
            if_else(age_3$label[which.max(age_3$estimate)] == "45" &
                      max(age_3$estimate) > 0, "yes", "no"))
evidence(paste0(estimate_list(age_3, digits = 1, scale = 100),
                " pp, each against a 35-year-old reference of 0.0"))

# "In partisan elections, we observe a similar pattern, though the effects for the
# political experience variables are more muted."
pol_3_partisan <- estimates(figure_3, panel == "Partisan", coef_group == "Pol. Experience")
report_text("desc_partisan_pol_exp_more_muted",
            "Is every political experience effect smaller in the partisan panel (MTurk)",
            if_else(all(pol_3_partisan$estimate <
                          pol_3$estimate[match(pol_3_partisan$label, pol_3$label)]),
                    "yes", "no"))
evidence(paste0("partisan ", estimate_list(pol_3_partisan, digits = 1, scale = 100),
                " pp against nonpartisan ", estimate_list(pol_3, digits = 1, scale = 100), " pp"))

# "On average, our sample prefers independents to partisan candidates of either
# stripe, though this average masks some heterogeneity by respondent party
# identification, as we will explore in the next section."
party_3 <- estimates(figure_3, panel == "Partisan", coef_group == "Party")
report_text("desc_prefers_independents",
            "Are both partisan candidate effects negative against an independent (MTurk)",
            if_else(all(party_3$estimate < 0), "yes", "no"))
evidence(paste0(estimate_list(party_3, digits = 1, scale = 100),
                " pp, each against an Independent reference"))

# "The final column of Fig. 3 shows the difference between partisan and nonpartisan
# elections across the attributes they have in common. For job experience, race, age,
# and gender, the presence or absence of party labels makes no difference."
diff_3 <- estimates(figure_3, panel == "Difference")
diff_3_other <- filter(diff_3, coef_group != "Pol. Experience")
report_value("desc_difference_null_job_race_age_gender",
             "Figure 3, difference intervals excluding zero outside political experience",
             sum(excludes_zero(diff_3_other)), digits = 0)
evidence(paste0(nrow(diff_3_other), " levels across job experience, race, age and gender; ",
                estimate_list(diff_3_other, digits = 1, scale = 100), " pp"))

# "However, we do observe statistically significantly different weight being given to
# the political experience variables, depending on election type. In nonpartisan
# elections, the effects of candidates' political experience are approximately 10
# percentage points larger than in partisan elections."
diff_3_pol <- filter(diff_3, coef_group == "Pol. Experience")
report_value("desc_difference_significant_pol_experience",
             "Figure 3, political experience difference intervals excluding zero",
             sum(excludes_zero(diff_3_pol)), digits = 0)
evidence(paste0(nrow(diff_3_pol), " political experience levels; ",
                estimate_list(diff_3_pol, digits = 1, scale = 100), " pp"))

report_value("results_pol_exp_gap_pp",
             "Figure 3, mean political experience difference (pp)",
             100 * mean(diff_3_pol$estimate))
evidence(paste0("the four differences run ",
                formatC(100 * min(diff_3_pol$estimate), digits = 1, format = "f"), " to ",
                formatC(100 * max(diff_3_pol$estimate), digits = 1, format = "f"), " pp"))

# Results: Figure 4, YouGov main analysis ----

# "Figure 4 presents the identical analyses using the YouGov data. Overall, we observe
# a very similar pattern of results. In nonpartisan elections, political experience is
# heavily rewarded."
np_4 <- estimates(figure_4, panel == "Nonpartisan")
pol_4 <- filter(np_4, coef_group == "Pol. Experience")
other_4 <- filter(np_4, coef_group != "Pol. Experience")
report_text("desc_yougov_similar_pattern",
            "Is every political experience effect larger in magnitude than every other effect (YouGov, nonpartisan)",
            if_else(min(abs(pol_4$estimate)) > max(abs(other_4$estimate)), "yes", "no"))
evidence(paste0("political experience ", estimate_list(pol_4, digits = 1, scale = 100),
                " pp; largest other effect ",
                formatC(100 * max(abs(other_4$estimate)), digits = 1, format = "f"), " pp"))

# "We added the 'School Board President' level to test the alternative explanation
# that respondents prefer any experience to 'No Political Experience.' Indeed,
# respondents do prefer school board presidents to political neophytes, but higher
# offices are nevertheless preferred to school board presidents as well."
school_board_4 <- one(pol_4, "estimate", label == "School Board President")
higher_4 <- filter(pol_4, label != "School Board President")
report_text("desc_school_board_ordering",
            "Is School Board President above zero and below every higher office (YouGov, nonpartisan)",
            if_else(school_board_4 > 0 & all(higher_4$estimate > school_board_4), "yes", "no"))
evidence(paste0("School Board President = ",
                formatC(100 * school_board_4, digits = 1, format = "f"),
                " pp against a No Political Experience reference of 0.0; ",
                estimate_list(higher_4, digits = 1, scale = 100), " pp"))

# "In the YouGov sample, we observe a similar interaction between election type and
# the effects of political experience. Political experience matters more in
# nonpartisan elections."
diff_4_pol <- estimates(figure_4, panel == "Difference", coef_group == "Pol. Experience")
report_value("desc_yougov_pol_exp_interaction",
             "Figure 4, political experience differences that are positive",
             sum(diff_4_pol$estimate > 0), digits = 0)
evidence(paste0(nrow(diff_4_pol), " levels; ",
                estimate_list(diff_4_pol, digits = 1, scale = 100), " pp; ",
                sum(excludes_zero(diff_4_pol)), " of them exclude zero"))

# "We added the 'Stay-at-Home Dad/Mom' and 'Electrician' levels to the job experience
# attribute. Both of these careers were viewed negatively in both partisan and
# nonpartisan elections."
added_labels <- c("Stay-at-Home Dad/Mom", "Electrician")
added_4 <- estimates(figure_4, panel %in% c("Nonpartisan", "Partisan"),
                     label %in% added_labels)
report_text("desc_stayathome_electrician_negative",
            "Are both added career levels negative in both election types (YouGov)",
            if_else(all(added_4$estimate < 0), "yes", "no"))
evidence(estimate_list(added_4, digits = 1, scale = 100,
                       name = paste0(added_4$panel, " ", added_4$label)))

# "We observe similarly small effects of gender and age in the YouGov sample as we did
# in the MTurk sample."
gender_age_4 <- filter(np_4, coef_group %in% c("Gender", "Age"))
gender_age_3 <- filter(np_3, coef_group %in% c("Gender", "Age"))
report_value("desc_yougov_small_gender_age",
             "Figure 4, largest gender or age effect, nonpartisan (pp)",
             100 * max(abs(gender_age_4$estimate)))
evidence(paste0("YouGov ", estimate_list(gender_age_4, digits = 1, scale = 100),
                " pp; MTurk ", estimate_list(gender_age_3, digits = 1, scale = 100), " pp"))

# Results: Figures 5 and 6, heterogeneous effects by respondent partisanship ----

# "As shown in the top center panel of each figure, Democrats dislike Republican
# candidates and Republicans dislike Democratic candidates. The differences in these
# preferences are large and statistically significant."
outparty <- bind_rows(
  estimates(figure_5, panel == "Partisan", party == "Democrats", label == "Republican") |>
    mutate(sample = "MTurk"),
  estimates(figure_5, panel == "Partisan", party == "Republicans", label == "Democrat") |>
    mutate(sample = "MTurk"),
  estimates(figure_6, panel == "Partisan", party == "Democrats", label == "Republican") |>
    mutate(sample = "YouGov"),
  estimates(figure_6, panel == "Partisan", party == "Republicans", label == "Democrat") |>
    mutate(sample = "YouGov")
)
report_text("desc_partisans_dislike_outparty_candidates",
            "Is every out-party candidate effect negative and clear of zero",
            if_else(all(outparty$estimate < 0) & all(excludes_zero(outparty)), "yes", "no"))
evidence(estimate_list(outparty, digits = 1, scale = 100,
                       name = paste0(outparty$sample, " ", outparty$party,
                                     " on ", outparty$label)))

# "Intriguingly, in both the MTurk and YouGov samples, partisans dislike the out-party
# (relative to an independent candidate) more than they like the in-party."
inparty <- bind_rows(
  estimates(figure_5, panel == "Partisan", party == "Democrats", label == "Democrat") |>
    mutate(sample = "MTurk"),
  estimates(figure_5, panel == "Partisan", party == "Republicans", label == "Republican") |>
    mutate(sample = "MTurk"),
  estimates(figure_6, panel == "Partisan", party == "Democrats", label == "Democrat") |>
    mutate(sample = "YouGov"),
  estimates(figure_6, panel == "Partisan", party == "Republicans", label == "Republican") |>
    mutate(sample = "YouGov")
)
report_text("desc_dislike_outparty_more_than_like_inparty",
            "Does out-party dislike exceed in-party liking in both samples for both parties",
            if_else(all(abs(outparty$estimate) > abs(inparty$estimate)), "yes", "no"))
evidence(paste0("out-party ", estimate_list(outparty, digits = 1, scale = 100,
                                            name = paste0(outparty$sample, " ", outparty$party)),
                " pp against in-party ",
                estimate_list(inparty, digits = 1, scale = 100,
                              name = paste0(inparty$sample, " ", inparty$party)), " pp"))

# "When we disaggregate by respondent partisan identification, we do see some small
# patterns with respect to candidate gender and race emerge. Republican respondents
# marginally prefer white candidates while Democrats marginally prefer nonwhite
# candidates."
race_56 <- bind_rows(
  estimates(figure_5, panel == "Nonpartisan", coef_group == "Race") |> mutate(sample = "MTurk"),
  estimates(figure_6, panel == "Nonpartisan", coef_group == "Race") |> mutate(sample = "YouGov")
)
report_text("desc_race_preference_by_respondent_party",
            "Are the nonwhite effects positive for Democrats and negative for Republicans in both samples (nonpartisan)",
            if_else(all(race_56$estimate[race_56$party == "Democrats"] > 0) &
                      all(race_56$estimate[race_56$party == "Republicans"] < 0), "yes", "no"))
evidence(estimate_list(race_56, digits = 1, scale = 100,
                       name = paste0(race_56$sample, " ", race_56$party, " ", race_56$label)))

# "Republicans do not appear to have a gender preference, while Democrats are 10
# percentage points more likely to choose a female candidate than a male candidate."
# The sentence names no sample, and the paragraph covers Figures 5 and 6, so all four
# estimates are printed rather than one being chosen for it.
male_rep <- bind_rows(
  estimates(figure_5, coef_group == "Gender", party == "Republicans",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "MTurk"),
  estimates(figure_6, coef_group == "Gender", party == "Republicans",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "YouGov")
)
report_value("desc_republicans_no_gender_preference",
             "Figures 5 and 6, Republican gender intervals excluding zero",
             sum(excludes_zero(male_rep)), digits = 0)
evidence(estimate_list(male_rep, digits = 1, scale = 100,
                       name = paste0(male_rep$sample, " ", male_rep$panel)))

male_dem <- bind_rows(
  estimates(figure_5, coef_group == "Gender", party == "Democrats",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "MTurk"),
  estimates(figure_6, coef_group == "Gender", party == "Democrats",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "YouGov")
)
report_text("results_democrats_female_preference_pp",
            "Figures 5 and 6, Democrat preference for a female over a male candidate (pp)",
            paste0(formatC(-100 * max(male_dem$estimate), digits = 1, format = "f"), " to ",
                   formatC(-100 * min(male_dem$estimate), digits = 1, format = "f")))
evidence(estimate_list(male_dem, digits = 1, scale = -100,
                       name = paste0(male_dem$sample, " ", male_dem$panel)))

# "These race and gender patterns do not differ much by election type."
race_gender_diff_5 <- estimates(figure_5, panel == "Difference",
                                coef_group %in% c("Race", "Gender"))
report_value("desc_race_gender_patterns_stable_across_election_type",
             "Figure 5, race and gender difference intervals excluding zero",
             sum(excludes_zero(race_gender_diff_5)), digits = 0)
evidence(paste0(nrow(race_gender_diff_5), " estimates; ",
                estimate_list(race_gender_diff_5, digits = 1, scale = 100,
                              name = paste0(race_gender_diff_5$party, " ",
                                            race_gender_diff_5$label)), " pp"))

# "Turning next to political experience, Republicans and Democrats both reward more
# highly-experienced candidates in both partisan and nonpartisan elections."
pol_56 <- bind_rows(
  estimates(figure_5, coef_group == "Pol. Experience",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "MTurk"),
  estimates(figure_6, coef_group == "Pol. Experience",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "YouGov")
)
report_value("desc_both_parties_reward_experience",
             "Figures 5 and 6, political experience estimates that are positive",
             sum(pol_56$estimate > 0), digits = 0)
evidence(paste0(nrow(pol_56), " estimates across two samples, two respondent parties and ",
                "two election types; the smallest is ",
                formatC(100 * min(pol_56$estimate), digits = 1, format = "f"), " pp"))

# "However, our main theoretical prediction - that political experience will matter
# more in nonpartisan elections than in partisan elections - is only borne out among
# Democratic respondents, not Republican respondents. This pattern is clearest in the
# MTurk sample, though it does obtain in the YouGov sample as well."
pol_diff_5 <- estimates(figure_5, panel == "Difference", coef_group == "Pol. Experience")
pol_diff_6 <- estimates(figure_6, panel == "Difference", coef_group == "Pol. Experience")
report_text("desc_prediction_only_among_democrats",
            "Do the political experience differences clear zero for Democrats but not Republicans (MTurk)",
            if_else(all(excludes_zero(filter(pol_diff_5, party == "Democrats"))) &
                      !any(excludes_zero(filter(pol_diff_5, party == "Republicans"))),
                    "yes", "no"))
evidence(estimate_list(pol_diff_5, digits = 1, scale = 100,
                       name = paste0(pol_diff_5$party, " ", pol_diff_5$label)))

report_text("desc_clearest_in_mturk",
            "Is the Democrat minus Republican gap in the political experience difference larger on MTurk",
            if_else(mean(pol_diff_5$estimate[pol_diff_5$party == "Democrats"]) -
                      mean(pol_diff_5$estimate[pol_diff_5$party == "Republicans"]) >
                      mean(pol_diff_6$estimate[pol_diff_6$party == "Democrats"]) -
                      mean(pol_diff_6$estimate[pol_diff_6$party == "Republicans"]),
                    "yes", "no"))
evidence(paste0("MTurk Democrats ",
                formatC(100 * mean(pol_diff_5$estimate[pol_diff_5$party == "Democrats"]),
                        digits = 1, format = "f"), " against Republicans ",
                formatC(100 * mean(pol_diff_5$estimate[pol_diff_5$party == "Republicans"]),
                        digits = 1, format = "f"), " pp; YouGov Democrats ",
                formatC(100 * mean(pol_diff_6$estimate[pol_diff_6$party == "Democrats"]),
                        digits = 1, format = "f"), " against Republicans ",
                formatC(100 * mean(pol_diff_6$estimate[pol_diff_6$party == "Republicans"]),
                        digits = 1, format = "f"), " pp"))

# "It may be that, in the absence of party labels, Republicans and Democrats turn to
# different markers of competence. In the YouGov sample, Republican respondents give
# greater weight to occupational experience in nonpartisan elections, while Democratic
# respondents give greater weight to political experience."
job_diff_6 <- estimates(figure_6, panel == "Difference", coef_group == "Job Experience")
report_text("desc_yougov_republicans_occupation_democrats_political",
            "Do the YouGov job experience differences run larger for Republicans and the political experience differences larger for Democrats",
            if_else(mean(job_diff_6$estimate[job_diff_6$party == "Republicans"]) >
                      mean(job_diff_6$estimate[job_diff_6$party == "Democrats"]) &
                      mean(pol_diff_6$estimate[pol_diff_6$party == "Democrats"]) >
                      mean(pol_diff_6$estimate[pol_diff_6$party == "Republicans"]),
                    "yes", "no"))
evidence(paste0("job experience ",
                estimate_list(job_diff_6, digits = 1, scale = 100,
                              name = paste0(job_diff_6$party, " ", job_diff_6$label)),
                " pp; political experience ",
                estimate_list(pol_diff_6, digits = 1, scale = 100,
                              name = paste0(pol_diff_6$party, " ", pol_diff_6$label)), " pp"))

# Mechanism: Candidate Competence ----

# "In order to assess the possiblity that the nonpartisan treatment operates by
# changing peceptions of candidate competence, we asked respondents to rate the
# competence of both candidates on a scale ranging from 0 to 100."
report_value("mechanism_competence_scale_min", "Competence scale minimum (YouGov)",
             design_value("YouGov", "competence_scale_min"), digits = 0)
report_value("mechanism_competence_scale_max", "Competence scale maximum (YouGov)",
             design_value("YouGov", "competence_scale_max"), digits = 0)

# "Because subjects evaluate candidates on five attributes in the nonpartisan
# elections and on six attributes in the partisan elections, they may mechanically
# assign more weight to remaining traits when party is omitted."
report_value("mechanism_attributes_nonpartisan",
             "Attributes displayed in a nonpartisan election (YouGov)",
             design_value("YouGov", "attributes_nonpartisan"), digits = 0)
report_value("mechanism_attributes_partisan",
             "Attributes displayed in a partisan election (YouGov)",
             design_value("YouGov", "attributes_partisan"), digits = 0)

# "Most importantly, both Republicans and Democrats rate candidates as more competent
# when they have more political experience."
pol_78 <- bind_rows(
  estimates(figure_7, coef_group == "Pol. Experience",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "MTurk"),
  estimates(figure_8, coef_group == "Pol. Experience",
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "YouGov")
)
report_value("desc_both_parties_competence_experience",
             "Figures 7 and 8, political experience competence estimates that are positive",
             sum(pol_78$estimate > 0), digits = 0)
evidence(paste0(nrow(pol_78), " estimates; they run ",
                formatC(min(pol_78$estimate), digits = 1, format = "f"), " to ",
                formatC(max(pol_78$estimate), digits = 1, format = "f"),
                " points on the 0 to 100 competence scale"))

# "As shown in the difference column, Democratic respondents (but not Republican
# respondents) rate such candidates as even more competent in the absence of party
# labels."
pol_diff_7 <- estimates(figure_7, panel == "Difference", coef_group == "Pol. Experience")
report_text("desc_democrats_competence_gap_nonpartisan",
            "Do the competence differences clear zero for Democrats but not Republicans (MTurk)",
            if_else(any(excludes_zero(filter(pol_diff_7, party == "Democrats"))) &
                      !any(excludes_zero(filter(pol_diff_7, party == "Republicans"))),
                    "yes", "no"))
evidence(paste0(sum(excludes_zero(filter(pol_diff_7, party == "Democrats"))), " of ",
                sum(pol_diff_7$party == "Democrats"),
                " Democrat intervals and ",
                sum(excludes_zero(filter(pol_diff_7, party == "Republicans"))), " of ",
                sum(pol_diff_7$party == "Republicans"),
                " Republican intervals exclude zero: ",
                estimate_list(pol_diff_7, digits = 1,
                              name = paste0(pol_diff_7$party, " ", pol_diff_7$label)),
                " points"))

# "We observe small effects of race, gender, and age on competence ratings, although
# across both datasets, Republican respondents appear to rate white candidates as
# marginally more competent than nonwhite candidates, while the opposite pattern holds
# for Democratic respondents."
demog_78 <- bind_rows(
  estimates(figure_7, coef_group %in% c("Race", "Gender", "Age"),
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "MTurk"),
  estimates(figure_8, coef_group %in% c("Race", "Gender", "Age"),
            panel %in% c("Nonpartisan", "Partisan")) |> mutate(sample = "YouGov")
)
report_value("desc_small_race_gender_age_competence",
             "Figures 7 and 8, largest race, gender or age competence effect (points)",
             max(abs(demog_78$estimate)))
evidence(paste0(nrow(demog_78), " estimates, mean magnitude ",
                formatC(mean(abs(demog_78$estimate)), digits = 2, format = "f"),
                " points against political experience estimates running to ",
                formatC(max(pol_78$estimate), digits = 1, format = "f")))

race_78 <- filter(demog_78, coef_group == "Race")
report_text("desc_republicans_white_more_competent",
            "Are the mean nonwhite competence effects negative for Republicans and positive for Democrats in both samples",
            if_else(all(map_dbl(c("MTurk", "YouGov"),
                                \(s) mean(race_78$estimate[race_78$sample == s &
                                                             race_78$party == "Republicans"])) < 0) &
                      all(map_dbl(c("MTurk", "YouGov"),
                                  \(s) mean(race_78$estimate[race_78$sample == s &
                                                               race_78$party == "Democrats"])) > 0),
                    "yes", "no"))
evidence(paste0("mean nonwhite effect, MTurk Democrats ",
                formatC(mean(race_78$estimate[race_78$sample == "MTurk" &
                                                race_78$party == "Democrats"]),
                        digits = 2, format = "f"), " and Republicans ",
                formatC(mean(race_78$estimate[race_78$sample == "MTurk" &
                                                race_78$party == "Republicans"]),
                        digits = 2, format = "f"), "; YouGov Democrats ",
                formatC(mean(race_78$estimate[race_78$sample == "YouGov" &
                                                race_78$party == "Democrats"]),
                        digits = 2, format = "f"), " and Republicans ",
                formatC(mean(race_78$estimate[race_78$sample == "YouGov" &
                                                race_78$party == "Republicans"]),
                        digits = 2, format = "f")))

# "We observe larger differences in competence ratings by occupation, with Republican
# respondents rating police officers, small business owners, and business executives
# more highly than educators, while Democrats hold the opposite views on such
# candidates."
trio <- c("Police Officer", "Small Business Owner", "Business Executive")
trio_78 <- bind_rows(
  estimates(figure_7, label %in% trio, panel == "Nonpartisan") |> mutate(sample = "MTurk"),
  estimates(figure_8, label %in% trio, panel == "Nonpartisan") |> mutate(sample = "YouGov")
)
report_text("desc_occupation_competence_by_party",
            "Are all three occupations rated above educators by Republicans and below by Democrats (nonpartisan)",
            if_else(all(trio_78$estimate[trio_78$party == "Republicans"] > 0) &
                      all(trio_78$estimate[trio_78$party == "Democrats"] < 0), "yes", "no"))
evidence(estimate_list(trio_78, digits = 2,
                       name = paste0(trio_78$sample, " ", trio_78$party, " ", trio_78$label)))

# "Neither party's respondents rated stay-at-home parents as more competent than
# educators."
stayathome_8 <- estimates(figure_8, label == "Stay-at-Home Dad/Mom",
                          panel %in% c("Nonpartisan", "Partisan"))
report_text("desc_stayathome_not_more_competent",
            "Is every stay-at-home parent competence effect at or below zero (YouGov)",
            if_else(all(stayathome_8$estimate <= 0), "yes", "no"))
evidence(paste0(estimate_list(stayathome_8, digits = 2,
                              name = paste0(stayathome_8$panel, " ", stayathome_8$party)),
                " points against an Educator reference; the level is not in the MTurk design"))

# "The same candidate types that respondents view as more competent are the ones that
# they tend to elect at higher rates in nonpartisan elections."
competence_np <- estimates(figure_c3, panel == "Nonpartisan")
paired_np <- inner_join(select(np_3, label, choice = estimate),
                        select(competence_np, label, competence = estimate),
                        by = "label")
report_value("desc_competent_types_elected_nonpartisan",
             "MTurk nonpartisan, correlation of candidate preference and competence effects",
             cor(paired_np$choice, paired_np$competence), digits = 2)
evidence(paste0(nrow(paired_np), " attribute levels; the political experience levels are ",
                "the largest on both, ",
                estimate_list(filter(competence_np, label %in% pol_3$label), digits = 1),
                " points on competence"))

# "The results (presented in detail in Appendix C.2) suggest that respondents,
# regardless of party, use occupation as a shortcut for ideology in nonpartisan
# elections. For example, both Democrats and Republicans view small business owners
# and business executives as more likely to implement conservative policies, and there
# is some suggestive evidence that this effect is stronger in nonpartisan elections."
# No Appendix C.2 exists and this analysis appears nowhere in the published appendix.
# The direction of the policy index is documented nowhere either, so the candidate's
# own party label is the anchor: a Republican candidate raises the index and a
# Democrat lowers it in every cell, which fixes the high end as the conservative end.
policy_anchor <- estimates(policy, panel == "Partisan", coef_group == "Party")
policy_business <- estimates(policy, panel == "Nonpartisan",
                             label %in% c("Small Business Owner", "Business Executive"))
report_text("desc_policy_index_business_conservative",
            "Are both business levels positive on the policy index for both parties in both samples",
            if_else(all(policy_business$estimate > 0), "yes", "no"))
evidence(paste0("polarity anchor, ",
                estimate_list(policy_anchor, digits = 2,
                              name = paste0(policy_anchor$sample, " ", policy_anchor$party,
                                            " on a ", policy_anchor$label, " candidate")),
                ". Business levels, ",
                estimate_list(policy_business, digits = 2,
                              name = paste0(policy_business$sample, " ",
                                            policy_business$party, " ",
                                            policy_business$label))))

# "Indeed, Democrats prefer experienced candidates in nonpartisan elections, but they
# do not see these candidates as more likely to implement liberal policies."
policy_pol_dem <- estimates(policy, panel == "Nonpartisan", party == "Democrats",
                            coef_group == "Pol. Experience")
report_value("desc_policy_index_democrats_experience",
             "Policy index, Democrat respondents, political experience intervals excluding zero",
             sum(excludes_zero(policy_pol_dem)), digits = 0)
evidence(paste0(nrow(policy_pol_dem), " estimates across the two samples, ",
                sum(policy_pol_dem$estimate < 0), " of them in the liberal direction; ",
                estimate_list(policy_pol_dem, digits = 2,
                              name = paste0(policy_pol_dem$sample, " ",
                                            policy_pol_dem$label))))

# "Appendix C.3 reports the results of this analysis. At least in the Mechanical Turk
# sample, we find that subjects give greater weight to political experience in
# same-party elections compared with cross-party elections."
satisficing_b1 <- estimates(figure_b1, panel == "Difference",
                            coef_group == "Pol. Experience")
report_value("desc_satisficing_mturk_same_party",
             "Figure B.1, same-party minus cross-party political experience differences that are positive",
             sum(satisficing_b1$estimate > 0), digits = 0)
evidence(paste0(nrow(satisficing_b1), " levels; ",
                estimate_list(satisficing_b1, digits = 1, scale = 100), " pp, of which ",
                sum(excludes_zero(satisficing_b1)), " exclude zero"))

# Discussion ----

# "The effect of previous political experience was shown to be statistically
# significantly larger in nonpartisan elections."
pol_diff_34 <- bind_rows(mutate(diff_3_pol, sample = "MTurk"),
                         mutate(diff_4_pol, sample = "YouGov"))
report_value("desc_pol_exp_effect_larger_nonpartisan",
             "Figures 3 and 4, political experience differences excluding zero",
             sum(excludes_zero(pol_diff_34)), digits = 0)
evidence(paste0(nrow(pol_diff_34), " levels across the two samples; ",
                estimate_list(pol_diff_34, digits = 1, scale = 100,
                              name = paste0(pol_diff_34$sample, " ", pol_diff_34$label)), " pp"))

# "In the appendix, we explore the correspondence across samples more deeply, finding
# that the correlation of effect estimates is very strong at 0.95."
report_value("discussion_correlation",
             "Correlation of the MTurk and YouGov effect estimates",
             one(correlation, "correlation", method == "pearson",
                 specification == "archive (YouGov unweighted)"), digits = 2)
evidence(paste0("over ",
                one(correlation, "n_estimates", method == "pearson",
                    specification == "archive (YouGov unweighted)"),
                " shared attribute levels, on the archive's unweighted YouGov fits; ",
                "weighting them as the YouGov main-effects figure does gives ",
                round(one(correlation, "correlation", method == "pearson",
                          specification == "YouGov weighted"), 4)))

# Appendix title page ----

# "Candidate Choice without Party Labels: New Insights from U.S. Mayoral Elections
# 1945-2007 and Conjoint Survey Experiments"
report_value("appendix_title_year_first", "Appendix title, first election year",
             dataset$year_first, digits = 0)
report_value("appendix_title_year_last", "Appendix title, last election year",
             dataset$year_last, digits = 0)

# The appendix's own date, and the figure numbers its Appendix C captions call
# "Figure 1" and "Figure 2" where the article numbers the same figures 3 and 4, are
# facts about that document rather than about the data. They are classified structural
# and verified by reading the two documents side by side; see the report.

# Appendix Table A.1, demographic characteristics of the experimental samples ----

# The respondent party identification panel and the two sample sizes in the table's
# note, as this pipeline rebuilds them.
table_a1_party_rows <- table_a1 |>
  mutate(claim_id = paste0("table_a1_party_", str_to_lower(sample), "_",
                           str_to_lower(party_id)),
         label = paste0("Table A.1, ", sample, " ", party_id, " share"))

walk(seq_len(nrow(table_a1_party_rows)),
     \(i) report_value(table_a1_party_rows$claim_id[i], table_a1_party_rows$label[i],
                       table_a1_party_rows$proportion[i], digits = 3))

report_value("table_a1_n_mturk", "Table A.1, MTurk respondents",
             one(table_a1, "n_respondents", sample == "mTurk", party_id == "Democrat"),
             digits = 0)
report_value("table_a1_n_yougov", "Table A.1, YouGov respondents",
             one(table_a1, "n_respondents", sample == "YouGov", party_id == "Democrat"),
             digits = 0)

# The rest of Table A.1 reports respondent race, gender, ideology, education and age.
# Neither deposited data file carries a respondent variable beyond party
# identification, so none of those cells has a counterpart anywhere in the pipeline.
# Each is listed so the gap is enumerated rather than described.
uncovered_a1 <- published_claims |>
  filter(location == "Table A.1", claim_type == "pipeline",
         !str_detect(claim_id, "^table_a1_(party|n)_"))

walk(seq_len(nrow(uncovered_a1)),
     \(i) report_text(uncovered_a1$claim_id[i],
                      paste0("Table A.1, published ", uncovered_a1$value_paper[i]),
                      "no counterpart: the deposit carries no respondent demographics beyond party identification"))
evidence(paste0(nrow(uncovered_a1), " of the table's ",
                sum(published_claims$location == "Table A.1" &
                      published_claims$claim_type == "pipeline"),
                " published cells have no counterpart in the deposit"))

# The five age band labels are definitional and belong to a panel the deposit cannot
# reach, so they are verified against the appendix itself and have no block.

# Appendix B, alternative mechanism: satisficing ----

# "In our application, subjects evaluate candidates on five attributes in the
# nonpartisan elections and on six attributes in the partisan elections."
report_value("appendix_b_attributes_nonpartisan",
             "Appendix B, attributes displayed in a nonpartisan election (MTurk)",
             design_value("mTurk", "attributes_nonpartisan"), digits = 0)
report_value("appendix_b_attributes_partisan",
             "Appendix B, attributes displayed in a partisan election (MTurk)",
             design_value("mTurk", "attributes_partisan"), digits = 0)

# "On MTurk, we observe a statistically significant interaction: the effects for the
# political experience attribute are stronger when candidates are from the same
# party."
report_value("desc_appendix_b_mturk_significant_interaction",
             "Figure B.1, political experience interactions excluding zero",
             sum(excludes_zero(satisficing_b1)), digits = 0)
evidence(paste0(nrow(satisficing_b1), " levels; ",
                estimate_list(satisficing_b1, digits = 1, scale = 100), " pp"))

# "On YouGov, the effect of political experience does not vary across the two types of
# elections."
satisficing_b2 <- estimates(figure_b2, panel == "Difference",
                            coef_group == "Pol. Experience")
report_value("desc_appendix_b_yougov_no_variation",
             "Figure B.2, political experience interactions excluding zero",
             sum(excludes_zero(satisficing_b2)), digits = 0)
evidence(paste0(nrow(satisficing_b2), " levels; ",
                estimate_list(satisficing_b2, digits = 1, scale = 100), " pp"))

# Appendix C, mechanism: competence ----

# "In addition to candidate preference, we also asked respondents to rate the
# candidates in terms of their competence: 'On a scale from 0 to 100, how competent do
# you think these candidates would be as mayor?'"
report_value("appendix_c_competence_scale_min",
             "Appendix C, competence scale minimum (MTurk)",
             design_value("mTurk", "competence_scale_min"), digits = 0)
report_value("appendix_c_competence_scale_max",
             "Appendix C, competence scale maximum (MTurk)",
             design_value("mTurk", "competence_scale_max"), digits = 0)

# "In this section, we reproduce Figures 1 and 2 from the main text using this
# alternative dependent variable. The results are very similar, but we present them
# here for completeness."
choice_c4 <- estimates(figure_4, panel == "Nonpartisan") |> select(label, choice = estimate)
competence_c4 <- estimates(figure_c4, panel == "Nonpartisan") |>
  select(label, competence = estimate)
paired_c4 <- inner_join(choice_c4, competence_c4, by = "label")
report_value("desc_appendix_c_results_similar",
             "YouGov nonpartisan, correlation of candidate preference and competence effects",
             cor(paired_c4$choice, paired_c4$competence), digits = 2)
evidence(paste0("MTurk gives ",
                formatC(cor(paired_np$choice, paired_np$competence), digits = 2, format = "f"),
                " over ", nrow(paired_np), " levels and YouGov ",
                formatC(cor(paired_c4$choice, paired_c4$competence), digits = 2, format = "f"),
                " over ", nrow(paired_c4)))
