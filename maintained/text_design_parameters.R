# kirkland_coppock_2018/maintained/text_design_parameters.R
# Output: output/text_design_parameters.csv
# Depends on: helpers.R
# Description: The design facts the article states in prose: how many elections each
#   subject judged, how many candidates each election showed, how many attributes
#   were displayed in each election type, the levels of the age attribute, and the
#   endpoints of the competence scale.
#
# These are read out of the deposited data rather than asserted, because the article
# states each of them and nothing else in the pipeline reaches them.

source(here::here("maintained", "helpers.R"))

# The six attributes of Table 2, in the columns the deposited data uses ----
attribute_columns <- c("Race", "Political", "Job", "Gender", "Age", "Party")

# An attribute is displayed in an election type when it takes more than one value
# there. Party is constant at "non-partisan" in the nonpartisan elections, which is
# what makes those elections five-attribute rather than six.
displayed_attributes <- function(data) {
  sum(map_int(attribute_columns, \(col) n_distinct(data[[col]])) > 1)
}

sample_parameters <- function(data, respondent_col, sample_label) {
  # Rows per respondent-election. Three MTurk worker ids appear more than once in the
  # deposited file, so the maximum is not the design parameter; the modal count is,
  # and the number of departures from it is recorded beside it.
  rows_per_election <- count(data, .data[[respondent_col]], contest_no)$n
  modal_candidates <- as.numeric(names(which.max(table(rows_per_election))))

  tibble(
    sample = sample_label,
    parameter = c("respondents", "elections_per_subject", "candidates_per_election",
                  "elections_not_showing_two_candidates",
                  "attributes_nonpartisan", "attributes_partisan",
                  "competence_scale_min", "competence_scale_max"),
    value = c(
      n_distinct(data[[respondent_col]]),
      max(data$contest_no),
      modal_candidates,
      sum(rows_per_election != modal_candidates),
      displayed_attributes(filter(data, Party == "non-partisan")),
      displayed_attributes(filter(data, Party != "non-partisan")),
      min(data$comp, na.rm = TRUE),
      max(data$comp, na.rm = TRUE)
    )
  )
}

age_levels <- function(data, sample_label) {
  tibble(
    sample = sample_label,
    parameter = paste0("age_level_", seq_along(sort(unique(as.numeric(as.character(data$Age)))))),
    value = sort(unique(as.numeric(as.character(data$Age))))
  )
}

design_parameters <- bind_rows(
  sample_parameters(mturk_clean, "resp_mturkid", "mTurk"),
  age_levels(mturk_clean, "mTurk"),
  sample_parameters(yougov_clean, "caseid", "YouGov"),
  age_levels(yougov_clean, "YouGov")
)

write_csv(design_parameters,
          here("maintained", "output", "text_design_parameters.csv"))
