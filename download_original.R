# kirkland_coppock_2018/download_original.R
# Output: original/ (the deposited replication archive, not redistributed in this repo)
# Depends on: original_manifest.csv
# Description: Fetch the deposited archive from Harvard Dataverse and verify every
#   file. Run this once before running anything in maintained/. Re-running is free:
#   files already present with the right checksum are not downloaded again.
#
#   The manifest carries two checksums per file. md5_served is the MD5 of the bytes
#   Dataverse returns for `?format=original`, which is what this code was written
#   against. md5_published is the checksum Dataverse displays. Here all ten agree,
#   but they do not always: another deposit in this program carries three published
#   checksums that verify neither the original nor the derived tabular file, so
#   verification runs against md5_served and any disagreement is reported.
#
#   Three of the ten files were ingested by Dataverse into tabular .tab
#   representations; the served_as column records the name Dataverse gives the
#   derived file. `?format=original` returns the deposited bytes in every case.
#
#   One of those names is worth reading twice. The YouGov data is deposited as
#   yougov_replication.xlsx and is not a spreadsheet: it is an RData binary carrying
#   the wrong extension. This script writes it under the deposited name, and
#   maintained/helpers.R load()s it under that name, because renaming a deposited
#   file inside a reproduction is how the defect stops being visible.

library(tidyverse)
library(here)

here::i_am("download_original.R")

dataset_doi <- "doi:10.7910/DVN/WSUHI3"
base_url <- "https://dataverse.harvard.edu/api/access/datafile"

# Manifest ----
manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

dir.create(here::here("original"), showWarnings = FALSE)

# Download what is missing or wrong ----
# format=original asks for the deposited bytes rather than the tabular
# representation Dataverse derives for ingested files.
planned <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{dataverse_file_id}?format=original"),
    md5_local = unname(tools::md5sum(path)),
    needs_download = is.na(md5_local) | md5_local != md5_served
  )

walk2(
  planned$url[planned$needs_download],
  planned$path[planned$needs_download],
  function(url, path) download.file(url, destfile = path, mode = "wb", quiet = TRUE)
)

print(str_glue("Downloaded {sum(planned$needs_download)} of {nrow(planned)} files; ",
               "{sum(!planned$needs_download)} already present and verified."))

# Verify ----
verified <- planned |>
  mutate(
    md5_downloaded = unname(tools::md5sum(path)),
    match = md5_downloaded == md5_served,
    published_agrees = md5_served == md5_published
  ) |>
  select(file, bytes, md5_served, md5_downloaded, match, published_agrees)

print(verified, n = nrow(verified))

if (!all(verified$match)) {
  stop("Checksum mismatch: the downloaded archive does not match what Dataverse served when this code was written.")
}

print(str_glue("All {nrow(verified)} files match. ",
               "{sum(!verified$published_agrees)} carry a published checksum that disagrees."))
print(str_glue("Archive: {dataset_doi}"))
