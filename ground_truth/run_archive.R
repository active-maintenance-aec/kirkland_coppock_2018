# kirkland_coppock_2018/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first), original_manifest.csv
# Description: Runs every deposited script, each in a clean R session, from a scratch
#   copy of original/, and records how each one ends and which files the run writes.
#
#   The deposit is three analysis scripts, one helper file they all source, three data
#   files, two codebooks, and a README. mayors_source.R is only ever sourced, so it gets
#   no row of its own. The deposit has no cleaning script and ships no object that any
#   deposited script builds: its three data files are the data, and nothing in the
#   archive writes a data file. A copy stripped to data plus code is therefore the copy
#   as shipped, and the stripped pass is recorded as not run, with the reason, rather
#   than reported as a pass. The two checks below are what license that.
#
#   The scripts load "mturk_replication.rdata", "base_categories.rdata" and
#   "yougov_replication.rdata". The first two differ from the deposited names only in
#   case, so they load on a case-insensitive filesystem (macOS, Windows) and fail on a
#   case-sensitive one (Linux). The third names a file the deposit does not hold under
#   any casing. The outcomes recorded here are those of a case-insensitive filesystem,
#   which is what this script was run on.
#
#   This script is not part of run_all.R: it runs code the deposit ships, and the
#   result depends on the filesystem it runs on.

library(here)
library(tidyverse)
library(processx)

here::i_am("ground_truth/run_archive.R")

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

analysis_scripts <- c("mturk_replication.R", "yougov_replication.R",
                      "compare_samples_replication.R")
helper_scripts <- "mayors_source.R"
stopifnot(setequal(manifest$file[str_ends(manifest$file, "\\.R")],
                   c(analysis_scripts, helper_scripts)))

# The null case, asserted ----
# No deposited script saves or writes a data file, so nothing the deposit ships could
# have been built by it.
writes_data <- map_lgl(c(analysis_scripts, helper_scripts), \(f) {
  any(str_detect(read_lines(here::here("original", f)),
                 "\\b(save|saveRDS|write_rds|write\\.csv|write_csv|write\\.dta)\\("))
})
stopifnot(!any(writes_data))

# The as-shipped pass ----
# Each script runs in its own clean session (--vanilla), from the scratch copy as working
# directory, which is where each script's commented-out setwd("") points the reader.
scratch <- file.path(tempdir(), "as_shipped")
dir.create(scratch, showWarnings = FALSE)
file.copy(here::here("original", manifest$file), scratch, overwrite = TRUE)
copied_at <- file.mtime(file.path(scratch, manifest$file))
Sys.sleep(1)

timeout_seconds <- 600

run_script <- function(script) {
  result <- processx::run(
    "Rscript", c("--vanilla", script),
    wd = scratch, timeout = timeout_seconds, error_on_status = FALSE
  )
  # A killed script's dying words are not the reason it stopped, so the timeout is tested
  # before the error text is read.
  first_error <- str_subset(str_split_1(result$stderr, "\n"), "^Error")[1]
  tibble(
    script = script,
    exit_status = result$status,
    outcome = case_when(
      result$timeout ~ "timeout",
      result$status == 0 ~ "clean",
      .default = "error"
    ),
    stopped_at = case_when(
      result$timeout ~ str_glue("Killed at the {timeout_seconds} second limit"),
      result$status == 0 ~ NA_character_,
      .default = str_squish(first_error)
    )
  )
}

as_shipped <- map(analysis_scripts, run_script) |> list_rbind()

# What the pass wrote ----
# A deposited file whose modification time moved was written over, and its contents are
# compared against the checksum Dataverse serves. A file the deposit does not hold was
# added by the run.
after <- tibble(file = list.files(scratch, all.files = TRUE, no.. = TRUE)) |>
  mutate(path = file.path(scratch, file))

overwritten <- manifest |>
  mutate(path = file.path(scratch, file),
         written = file.mtime(path) > copied_at) |>
  filter(written) |>
  transmute(pass = "as_shipped", file, effect = "overwritten",
            matches_deposit = unname(tools::md5sum(path)) == md5_served)

added <- after |>
  filter(!file %in% manifest$file) |>
  transmute(pass = "as_shipped", file, effect = "added", matches_deposit = NA)

overwrites <- bind_rows(overwritten, added) |> arrange(effect, file)

# The two archive tables, in the canonical long form ----
stripped_reason <- str_c(
  "Not run: the deposit has no cleaning script and ships no object its code builds, ",
  "so the copy stripped to data plus code is the copy as shipped"
)

run_status <- bind_rows(
  as_shipped |> mutate(pass = "as_shipped"),
  tibble(pass = "stripped", script = analysis_scripts, exit_status = NA_integer_,
         outcome = "not_run", stopped_at = stripped_reason)
) |>
  mutate(role = "analysis") |>
  select(pass, script, role, exit_status, outcome, stopped_at)

stopifnot(nrow(run_status) == 2 * length(analysis_scripts),
          all(run_status$outcome %in% c("clean", "error", "timeout", "not_run")))

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))
print(run_status, width = 200)
print(overwrites)

# original/ is untouched ----
# The run happened in a copy, and this says so rather than assuming it.
stopifnot(all(unname(tools::md5sum(here::here("original", manifest$file))) ==
                manifest$md5_served))
