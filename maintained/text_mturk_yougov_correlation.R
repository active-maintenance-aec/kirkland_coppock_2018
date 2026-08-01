# kirkland_coppock_2018/maintained/text_mturk_yougov_correlation.R
# Output: output/text_mturk_yougov_correlation.csv
# Depends on: helpers.R
# Description: Correlation between the MTurk and YouGov effect estimates, the 0.95
#   the Discussion reports, and the scatterplot behind it.

source(here::here("maintained", "helpers.R"))

# compare_samples_replication.R fits the YouGov models without weights, unlike the
# YouGov main-effects figure in yougov_replication.R. That inconsistency inside the
# archive is what produces the published 0.95: weighting these four models instead
# gives a Pearson correlation of 0.92. The rewrite keeps the archive's unweighted
# specification and records the weighted value alongside so the gap is visible.
sample_estimates <- function(data, cluster_col, weighted) {
  d <- data |> mutate(cluster_id = .data[[cluster_col]])

  fit <- function(rhs, model_data) {
    fml <- as.formula(paste("win ~", rhs))
    if (weighted) {
      lm_robust(fml, data = model_data, weights = weight,
                clusters = cluster_id, se_type = "stata")
    } else {
      lm_robust(fml, data = model_data, clusters = cluster_id, se_type = "stata")
    }
  }

  main_rhs <- "Gender + Age + Race + Job + Political"

  bind_rows(
    fit(main_rhs, filter(d, Party == "non-partisan")) |>
      tidy() |> mutate(election_type = "nonpartisan"),
    fit(paste(main_rhs, "+ Party"), filter(d, Party != "non-partisan")) |>
      tidy() |> mutate(election_type = "partisan")
  ) |>
    filter(term != "(Intercept)") |>
    select(term, election_type, estimate, std.error)
}

mturk_estimates <- sample_estimates(mturk_clean, "resp_mturkid", weighted = FALSE)
yougov_estimates <- sample_estimates(yougov_clean, "caseid", weighted = FALSE)
yougov_weighted <- sample_estimates(yougov_clean, "caseid", weighted = TRUE)

# Only the levels both samples share can be compared; the YouGov-only levels have no
# MTurk counterpart, and an inner join drops them.
paired <- inner_join(mturk_estimates, yougov_estimates,
                     by = c("term", "election_type"),
                     suffix = c("_mturk", "_yougov"))

paired_weighted <- inner_join(mturk_estimates, yougov_weighted,
                              by = c("term", "election_type"),
                              suffix = c("_mturk", "_yougov"))

correlations <- tibble(
  specification = c("archive (YouGov unweighted)", "archive (YouGov unweighted)",
                    "YouGov weighted", "YouGov weighted"),
  method = c("pearson", "spearman", "pearson", "spearman"),
  n_estimates = c(rep(nrow(paired), 2), rep(nrow(paired_weighted), 2)),
  correlation = c(
    cor(paired$estimate_mturk, paired$estimate_yougov, method = "pearson"),
    cor(paired$estimate_mturk, paired$estimate_yougov, method = "spearman"),
    cor(paired_weighted$estimate_mturk, paired_weighted$estimate_yougov, method = "pearson"),
    cor(paired_weighted$estimate_mturk, paired_weighted$estimate_yougov, method = "spearman")
  )
)

write_csv(correlations, here("maintained", "output",
                             "text_mturk_yougov_correlation.csv"))

# Scatterplot of the two samples' estimates ----
gg_df <- paired |>
  mutate(mturk_low = estimate_mturk - 1.96 * std.error_mturk,
         mturk_high = estimate_mturk + 1.96 * std.error_mturk,
         yougov_low = estimate_yougov - 1.96 * std.error_yougov,
         yougov_high = estimate_yougov + 1.96 * std.error_yougov,
         election_type = str_to_title(election_type))

g <- ggplot(gg_df, aes(x = estimate_mturk, y = estimate_yougov,
                       shape = election_type)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_linerange(aes(ymin = yougov_low, ymax = yougov_high), alpha = 0.5) +
  geom_linerange(aes(xmin = mturk_low, xmax = mturk_high), alpha = 0.5) +
  geom_point(size = 3) +
  scale_shape_manual(values = c(Nonpartisan = 1, Partisan = 19)) +
  coord_cartesian(xlim = c(-0.4, 0.4), ylim = c(-0.4, 0.4)) +
  labs(x = "Mechanical Turk estimate", y = "YouGov estimate") +
  theme_bw() +
  theme(legend.position = "bottom", legend.title = element_blank())

ggsave(here("maintained", "output", "text_mturk_yougov_correlation.pdf"),
       plot = g, width = 6, height = 6)
ggsave(here("maintained", "output", "text_mturk_yougov_correlation.png"),
       plot = g, width = 6, height = 6, dpi = 300)
