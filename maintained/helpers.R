# kirkland_coppock_2018/maintained/helpers.R
# Output: (none; sourced by every analysis script)
# Depends on: original/mturk_replication.RData, original/yougov_replication.xlsx
# Description: Packages, the two conjoint datasets, and the shared estimation,
#   labelling and plotting helpers used by the figure and table scripts.

library(here)
library(tidyverse)
library(estimatr)

here::i_am("maintained/helpers.R")

# Deposited data ----
# yougov_replication.xlsx is the name the file carries in the deposit. Despite the
# extension it is an RData binary, and load() reads it correctly. download_original.R
# writes it to original/ under the deposited name, so nothing here renames it. The
# archive's own scripts call load("yougov_replication.rdata"), a file the deposit
# does not contain; see the report.
load(here("original", "mturk_replication.RData"))
load(here("original", "yougov_replication.xlsx"))

# Attribute display order, bottom to top in every figure ----
# Holds the MTurk and YouGov levels together. A level absent from a sample simply
# produces no coefficient there.
attr_levels <- c(
  "Male", "Base category: Female",
  "65", "55", "45", "Base category: 35",
  "Asian", "Black", "Hispanic", "Base category: White",
  "Attorney", "Business Executive", "Small Business Owner", "Police Officer",
  "Electrician", "Stay-at-Home Dad/Mom", "Base category: Educator",
  "Representative in Congress", "Mayor", "State Legislator", "City Council Member",
  "School Board President", "Base category: No Political Experience",
  "Republican", "Democrat", "Base category: Independent"
)

coef_group_levels <- c("Party", "Pol. Experience", "Job Experience",
                       "Race", "Age", "Gender")

group_label <- function(label) {
  case_when(
    label %in% c("Male", "Base category: Female")
      ~ "Gender",
    label %in% c("45", "55", "65", "Base category: 35")
      ~ "Age",
    label %in% c("Hispanic", "Black", "Asian", "Base category: White")
      ~ "Race",
    label %in% c("Police Officer", "Small Business Owner", "Business Executive",
                 "Attorney", "Electrician", "Stay-at-Home Dad/Mom",
                 "Base category: Educator")
      ~ "Job Experience",
    label %in% c("City Council Member", "State Legislator", "Mayor",
                 "Representative in Congress", "School Board President",
                 "Base category: No Political Experience")
      ~ "Pol. Experience",
    label %in% c("Democrat", "Republican", "Base category: Independent")
      ~ "Party",
    .default = NA_character_
  )
}

# Strip the variable-name prefix and any interaction suffix from a term ----
label_term <- function(term) {
  term |>
    str_remove(":(nonpartisan|same_party)$") |>
    str_remove("^(Gender|Age|Race|Job|Political|Party)")
}

# Base category placeholder rows ----
# The published figures put each reference level on the axis with no marker, which is
# what an NA estimate produces.
base_category_rows <- function(panel, include_party) {
  labels <- c("Base category: Female", "Base category: 35", "Base category: White",
              "Base category: Educator", "Base category: No Political Experience")
  if (include_party) labels <- c(labels, "Base category: Independent")
  expand_grid(label = labels, panel = panel) |>
    mutate(estimate = NA_real_, std.error = NA_real_,
           conf.low = NA_real_, conf.high = NA_real_)
}

# Confidence bounds as the archive draws them ----
# The published figures use estimate +/- 1.96 * SE rather than a t quantile on the
# cluster-adjusted degrees of freedom, so the rewrite draws them the same way.
add_normal_ci <- function(df) {
  df |> mutate(conf.low = estimate - 1.96 * std.error,
               conf.high = estimate + 1.96 * std.error)
}

# Three-panel estimates by election type ----
# Equation 1 among nonpartisan elections, Equation 2 among partisan elections, and an
# interacted model on the full sample whose ":nonpartisan" coefficients are the
# difference between the first two.
#
# se_type = "stata" reproduces the archive's cl() helper exactly: both scale the CR0
# meat by (M / (M - 1)) * ((N - 1) / (N - K)). estimatr called this estimator "CR1S"
# until version 1.0.6 retired the name.
#
# `weighted` has no default on purpose. The archive applies the YouGov sample weights
# to the main-effect and satisficing figures but not to the heterogeneous-effects
# figures, so the choice has to be made and shown at every call site.
election_type_panels <- function(data, dv, cluster_col, weighted) {
  d <- data |>
    mutate(nonpartisan = as.integer(Party == "non-partisan"),
           cluster_id = .data[[cluster_col]])

  fit <- function(rhs, model_data) {
    fml <- as.formula(paste(dv, "~", rhs))
    if (weighted) {
      lm_robust(fml, data = model_data, weights = weight,
                clusters = cluster_id, se_type = "stata")
    } else {
      lm_robust(fml, data = model_data, clusters = cluster_id, se_type = "stata")
    }
  }

  main_rhs <- "Gender + Age + Race + Job + Political"
  diff_rhs <- paste("(Gender + Age + Race + Job + Political) * nonpartisan +",
                    "I(Party == 'Democrat') + I(Party == 'Republican')")

  np <- fit(main_rhs, filter(d, nonpartisan == 1)) |>
    tidy() |>
    filter(term != "(Intercept)") |>
    mutate(label = label_term(term), panel = "Nonpartisan")

  p <- fit(paste(main_rhs, "+ Party"), filter(d, nonpartisan == 0)) |>
    tidy() |>
    filter(term != "(Intercept)") |>
    mutate(label = label_term(term), panel = "Partisan")

  diff <- fit(diff_rhs, d) |>
    tidy() |>
    filter(str_detect(term, ":nonpartisan$")) |>
    mutate(label = label_term(term), panel = "Difference")

  bind_rows(np, p, diff) |>
    select(label, panel, estimate, std.error) |>
    add_normal_ci() |>
    bind_rows(base_category_rows("Nonpartisan", include_party = FALSE),
              base_category_rows(c("Partisan", "Difference"), include_party = TRUE))
}

# Three-panel estimates by whether the two candidates share a party ----
# The satisficing check in Appendix B. Both panels hold the number of displayed
# attributes fixed at six, so only the informativeness of the party label varies.
same_party_panels <- function(data, dv, cluster_col, weighted) {
  d <- data |>
    filter(Party != "non-partisan") |>
    mutate(cluster_id = .data[[cluster_col]])

  fit <- function(rhs, model_data) {
    fml <- as.formula(paste(dv, "~", rhs))
    if (weighted) {
      lm_robust(fml, data = model_data, weights = weight,
                clusters = cluster_id, se_type = "stata")
    } else {
      lm_robust(fml, data = model_data, clusters = cluster_id, se_type = "stata")
    }
  }

  main_rhs <- "Gender + Age + Race + Job + Political + Party"

  same <- fit(main_rhs, filter(d, same_party == 1)) |>
    tidy() |>
    filter(term != "(Intercept)") |>
    mutate(label = label_term(term), panel = "Same Party")

  different <- fit(main_rhs, filter(d, same_party == 0)) |>
    tidy() |>
    filter(term != "(Intercept)") |>
    mutate(label = label_term(term), panel = "Different Parties")

  diff <- fit(paste0("(", main_rhs, ") * same_party"), d) |>
    tidy() |>
    filter(str_detect(term, ":same_party$")) |>
    mutate(label = label_term(term), panel = "Difference")

  bind_rows(same, different, diff) |>
    select(label, panel, estimate, std.error) |>
    add_normal_ci() |>
    bind_rows(base_category_rows(c("Same Party", "Different Parties", "Difference"),
                                 include_party = TRUE))
}

# Factor levels and facet grouping ----
finalize_plot_df <- function(df, panel_levels) {
  df |>
    mutate(
      label = factor(label, levels = attr_levels),
      coef_group = factor(group_label(as.character(label)), levels = coef_group_levels),
      panel = factor(panel, levels = panel_levels)
    ) |>
    arrange(panel, label)
}

# Shared coefficient plot ----
# Attribute level on y, estimate on x, one facet column per panel and one facet row
# per attribute group. `by_party` dodges two series for the heterogeneous-effects
# figures, in the paper's colours.
conjoint_plot <- function(plot_df, xlim, breaks = waiver(), by_party = FALSE) {
  g <- ggplot(plot_df, aes(y = label, x = estimate))

  if (by_party) {
    g <- g +
      aes(group = party, color = party, shape = party) +
      scale_color_manual(values = c(Democrats = "blue", Republicans = "red")) +
      geom_point(position = position_dodge(width = 0.5), size = 1.5, na.rm = TRUE) +
      geom_linerange(aes(xmin = conf.low, xmax = conf.high),
                     position = position_dodge(width = 0.5), na.rm = TRUE)
  } else {
    g <- g +
      geom_point(size = 1.5, na.rm = TRUE) +
      geom_linerange(aes(xmin = conf.low, xmax = conf.high), na.rm = TRUE)
  }

  g <- g +
    geom_vline(xintercept = 0, linetype = "dashed") +
    facet_grid(coef_group ~ panel, scales = "free_y", space = "free_y") +
    coord_cartesian(xlim = xlim) +
    scale_x_continuous(breaks = breaks) +
    theme_bw() +
    theme(axis.title = element_blank(), strip.background = element_blank())

  if (by_party) {
    g <- g + theme(legend.position = "bottom", legend.title = element_blank())
  }
  g
}

# Write a figure and the estimates behind it ----
# The CSV is what makes a figure diffable: a PDF records the time it was written, so
# a rerun always shows a change there even when nothing moved.
save_figure <- function(g, plot_df, stem, width, height) {
  out <- function(ext) here("maintained", "output", paste0(stem, ".", ext))
  ggsave(out("pdf"), plot = g, width = width, height = height)
  ggsave(out("png"), plot = g, width = width, height = height, dpi = 300)
  write_csv(plot_df, out("csv"))
}

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
