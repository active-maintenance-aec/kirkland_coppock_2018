# kirkland_coppock_2018/maintained/text_policy_index_het_fx.R
# Output: output/text_policy_index_het_fx.csv
# Depends on: helpers.R
# Description: Heterogeneous effects of the candidate attributes on the policy-goal
#   index, by respondent party identification and election type, for both samples.
#
# The Mechanism section states results for this outcome and cites "Appendix C.2" for
# them. No such subsection exists in the published appendix and the analysis appears
# nowhere in it, so these estimates have no published counterpart. Both deposited
# scripts compute them (mturk_replication.R calls the result Figure C.6,
# yougov_replication.R Figure C.7), unweighted in both samples, and this script
# reproduces them so the sentences in the article can be checked against something.
#
# The direction of policy_index is documented nowhere: the codebook records only that
# it runs from 2 to 14, and the appendix section that would define it does not exist.
# The candidate's own party label is the fixed-direction anchor, so the Republican and
# Democrat coefficients in the partisan panel are what establish which end is which.

source(here::here("maintained", "helpers.R"))

policy_index_estimates <- bind_rows(
  election_type_panels(filter(mturk_clean, democrat == 1), dv = "policy_index",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(sample = "mTurk", party = "Democrats"),
  election_type_panels(filter(mturk_clean, republican == 1), dv = "policy_index",
                       cluster_col = "resp_mturkid", weighted = FALSE) |>
    mutate(sample = "mTurk", party = "Republicans"),
  election_type_panels(filter(yougov_clean, democrat == 1), dv = "policy_index",
                       cluster_col = "caseid", weighted = FALSE) |>
    mutate(sample = "YouGov", party = "Democrats"),
  election_type_panels(filter(yougov_clean, republican == 1), dv = "policy_index",
                       cluster_col = "caseid", weighted = FALSE) |>
    mutate(sample = "YouGov", party = "Republicans")
) |>
  finalize_plot_df(panel_levels = c("Nonpartisan", "Partisan", "Difference")) |>
  select(sample, party, label, panel, coef_group, estimate, std.error,
         conf.low, conf.high)

write_csv(policy_index_estimates,
          here("maintained", "output", "text_policy_index_het_fx.csv"))
