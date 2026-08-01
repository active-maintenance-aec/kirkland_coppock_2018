# Replication Archive for: 
# Kirkland, Patricia A. and Alexander Coppock
# Candidate Choice without Party Labels: New Insights from Conjoint Survey Experiments
# Forthcoming at Political Behavior
# Observational Study Replication

rm(list = ls())

# uncomment to set working directory
# setwd("")

# Source helper functions
source("mayors_source.R")

# uncomment to install packages
# install.packages("tidyverse")

library(tidyverse)

# load data
load("observational_mayors_replication.rdata")

election_level <-
  mayors %>% 
  group_by(contest_id) %>%
  summarize(
    winner_experience = experience_recoded[win == 1],
    runnerup_experience = experience_recoded[win == 0],
    fipsid = unique(fipsid),
    year = unique(year),
    partisan = unique(partisan)
  )

election_winners_tab <- with(election_level, table(winner_experience, partisan))
chisq.test(election_winners_tab, simulate.p.value = TRUE)


pol_experience_ns <-
  with(election_level, as.data.frame.matrix(table(winner_experience, partisan)))
pol_experience_props <-
  with(election_level, as.data.frame.matrix(prop.table(
    table(winner_experience, partisan), margin = 2
  )))


pol_experience_table <- data.frame(
  occupation = c(
    "No previous political experience",
    "City legislator",
    "County legislator",
    "State legislator",
    "US legislator",
    "Mayor"
  ),
  N_NP = pol_experience_ns[, 1],
  prop_NP = paste0(format_num(100 * pol_experience_props[, 1], 0), "%"),
  N_P = pol_experience_ns[, 2],
  prop_P = paste0(format_num(100 * pol_experience_props[, 2], 0), "%")
)
