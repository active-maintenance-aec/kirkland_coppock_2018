# kirkland_coppock_2018/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, then
# every published table, then every published figure, then the in-text quantities.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Tables ----
# table_1 reads the recovered observational data, which the deposit omits.
source(here::here("maintained", "table_1_observational_experience.R"))
source(here::here("maintained", "table_a1_party_identification.R"))

# Main text figures ----
source(here::here("maintained", "figure_3_mturk_main_candidate_pref.R"))
source(here::here("maintained", "figure_4_yougov_main_candidate_pref.R"))
source(here::here("maintained", "figure_5_mturk_het_fx_candidate_pref.R"))
source(here::here("maintained", "figure_6_yougov_het_fx_candidate_pref.R"))
source(here::here("maintained", "figure_7_mturk_het_fx_competence.R"))
source(here::here("maintained", "figure_8_yougov_het_fx_competence.R"))

# Appendix figures ----
source(here::here("maintained", "figure_b1_mturk_satisficing.R"))
source(here::here("maintained", "figure_b2_yougov_satisficing.R"))
source(here::here("maintained", "figure_c3_mturk_main_competence.R"))
source(here::here("maintained", "figure_c4_yougov_main_competence.R"))

# In-text quantities ----
source(here::here("maintained", "text_design_parameters.R"))
source(here::here("maintained", "text_observational_experience_advantage.R"))
source(here::here("maintained", "text_mturk_yougov_correlation.R"))
# The Mechanism section reports results for the policy-goal index and cites an
# appendix subsection that does not exist, so these estimates have no published
# counterpart; see the report.
source(here::here("maintained", "text_policy_index_het_fx.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes, and those two fields are the only reason two runs of this pipeline produce
# differing files. Blanking them lets the determinism check cover every file the
# pipeline writes rather than all but the figures.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Ground truth ----
# Rebuilds the comparison table from the outputs above, so it cannot go stale, and
# gates the coverage of maintained/in_text_claims.R against the published extraction.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims ----
# Every number the article and the appendix print, beside the sentence that prints it.
# build_ground_truth.R has already run this file non-interactively as its coverage
# gate; sourcing it here puts the output in front of anyone running the pipeline.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
