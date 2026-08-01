# Reproducibility Report: Kirkland and Coppock (2018)


- [Paper Overview](#paper-overview)
- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Original Archive Reproducibility](#original-archive-reproducibility)
- [Errata](#errata)
- [Ground Truth Verification](#ground-truth-verification)
- [Maintained Rewrite](#maintained-rewrite)
- [Figure Verification](#figure-verification)
- [Maintained Rewrite Verification](#maintained-rewrite-verification)
- [R Environment](#r-environment)

This repository holds the actively maintained replication code for
Kirkland and Coppock (2018), together with the reproducibility report
that documents what the original archive did and did not do. It is part
of a program applying the maintenance proposal in Peer, Orr and Coppock
(2021, *PS: Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1007/s11109-017-9414-8](https://doi.org/10.1007/s11109-017-9414-8) |
| Replication archive | [10.7910/DVN/WSUHI3](https://doi.org/10.7910/DVN/WSUHI3) |
| Pre-analysis plans | none |

**The data are not redistributed here.** The deposit lives at Harvard
Dataverse and that is the only copy this repository points at.
`download_original.R` fetches it and verifies every file;
`original_manifest.csv` records the Dataverse file identifiers, the UNF
of each ingested data file, and two checksums per file: the MD5 of the
bytes Dataverse serves, which is what this code was written against, and
the MD5 Dataverse publishes. Here the two agree for all 10 files. They
do not always, so the script verifies against the served bytes and
reports any disagreement. Either way the exact bytes are pinned in
version control even though the bytes themselves are not.

**`recovered/` is different and is committed.** The observational
analysis behind Table 1 depends on a data file and a script that the
deposit does not contain, though its own README lists both. The authors
supplied them, and since they exist nowhere else this repository carries
them.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything. `ground_truth/` ties every published number to the
code that produces it. `original/` is created by the download script and
is deliberately absent from the repository. This README is the
reproducibility report, also available as a PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains, so nothing in the chain is more restrictive than
the archive itself. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`kirkland_coppock_2018.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposited archive from Dataverse, verifies its 10
checksums, produces every published table and figure into
`maintained/output/`, and rebuilds the ground truth table from those
outputs. It takes about a minute. Individual scripts can be run on their
own in any order; only `ground_truth/build_ground_truth.R` depends on
the others having run first.

Required packages: tidyverse, estimatr, knitr, kableExtra, here. Paths
resolve through `here`, so nothing depends on the working directory and
the scripts work equally well under `Rscript` outside RStudio. A
successful run overwrites `maintained/output/`, which is committed:
**`git diff` on that folder is the reproduction check**, and the CSV and
PNG output should come back byte-identical. The eleven PDF figures
always show as changed, because a PDF records the time it was written;
compare their PNG twins instead.

## Paper Overview

**Citation**: Kirkland, P. A. and Coppock, A. (2018). Candidate choice
without party labels: New insights from conjoint survey experiments.
*Political Behavior*, 40(3), 571–591.

**Research question**: When a ballot carries no party label, what do
voters use instead? The paper argues that without the partisan shortcut
voters fall back on other indicators of fitness for office, political
experience above all.

**Design**: Three pieces of evidence. An observational record of 1,010
US mayoral elections held between 1945 and 2007 across 225
municipalities, comparing the political experience of winners under
partisan and nonpartisan ballots. Then two conjoint survey experiments
running the same design on different samples: an MTurk convenience
sample (N = 1,204) and a nationally representative YouGov sample (N =
1,200). Each subject judged five successive elections between two
candidates whose race, gender, age, career experience, political
experience and, in half the elections, party were fully randomized.
Outcomes are candidate choice and a 0 to 100 competence rating.
Estimation is OLS with standard errors clustered by respondent, and
effects are compared across election types by interacting every
attribute with an indicator for the nonpartisan ballot.

**Main finding**: Political experience carries substantially more weight
when the party label is withheld. In the MTurk sample the political
experience coefficients are about 10 percentage points larger in
nonpartisan than in partisan elections, and the same interaction appears
in the YouGov sample. The competence ratings move the same way, which is
the paper’s evidence for the mechanism it proposes. The two samples’
estimates correlate at 0.95.

------------------------------------------------------------------------

## Summary

Two questions, answered before the detail.

### Does the deposited archive run?

Not as deposited, and the reasons are all about files rather than about
code.

**The YouGov data cannot be loaded under the name the scripts use.** The
deposit contains `yougov_replication.xlsx`. It is not a spreadsheet: it
is an RData binary carrying the wrong extension, uploaded that way and
served that way ever since. Both scripts that need it call
`load("yougov_replication.rdata")`, so `yougov_replication.R` and
`compare_samples_replication.R` fail on their first data line. Renaming
the file, or loading it under its real name, fixes both, and the
extension is the whole of the problem: the bytes are a valid RData file
and `load()` reads them without complaint.

**Three of the twelve files the archive’s README promises were never
deposited.** The README lists `observational_mayors_replication.rdata`,
`observational_replication.R` and `observational_codebook.txt`, along
with CSV copies of all three data files. The Dataverse record has ten
files and none of those six are among them. Table 1 and the paragraph of
observational results that follows it therefore cannot be reproduced
from the deposit at all. The authors supplied the missing data and
script separately; they are in `recovered/` and the rewrite reads Table
1 from there.

**Every data path in the archive is mis-cased.** The scripts call
`load("mturk_replication.rdata")` and `load("base_categories.rdata")`;
the deposited files are `mturk_replication.RData` and
`base_categories.RData`. macOS and Windows do not care. Linux does,
which is where most people who clone a replication archive today are
running it.

With the YouGov file renamed, all three deposited scripts run to
completion in a current R and produce their figures. The only warning is
`geom_errorbarh()`, deprecated in ggplot2 4.0.0. Nothing in the archive
writes a file, so running it leaves the deposit untouched, and
re-verifying `original/` against the manifest after a full run confirms
all 10 files unchanged.

### Does the maintained rewrite reproduce the paper?

Yes for everything the paper prints, with exceptions in the
observational paragraph on page 5 and in one sentence describing Figure
3.

| Component | Verdict |
|:---|:---|
| Table 1 (24 cells plus both totals) | Reproduces exactly |
| Table 1 chi-squared statistic | Reproduces (21.2) |
| Table 1 chi-squared p-value | Reproduces; the archive’s test is an unseeded simulation and 0.002 is inside its range |
| Text p. 5, 779 elections | Reproduces exactly |
| Text p. 5, 62 and 61 per cent | Reproduce, but the two labels are transposed in the sentence |
| Text p. 5, p = 0.791 | Does not reproduce (0.852 here) |
| Text p. 5, 63 and 48 per cent | Not verifiable; candidate occupation is not in the recovered data |
| Table A.1 party identification panel and Ns | Reproduces exactly |
| Table A.1 remaining panels | Not verifiable; the deposit carries no other respondent demographics |
| Figures 3 to 8, B.1, B.2, C.3, C.4 | Reproduce; all 729 estimates and standard errors agree with the archive to 4e-13 |
| Text on Figure 3, 25 to 30 percentage points | Range is tight at both ends; the estimates run 22.7 to 32.0 |
| Text on Figure 3, about 10 percentage points | Reproduces (9.1 to 11.7) |
| Discussion, correlation of 0.95 | Reproduces (0.9494) on the archive’s specification |

Reproduction verdict by component

Of the 50 recorded ground truth claims, 46 are verifiable and 41 of them
match.

**The p-value that does not reproduce.** The paper reports that among
the 779 elections in which the two candidates had different levels of
political experience, the more experienced candidate won about 62 per
cent of the time in partisan elections and 61 per cent in nonpartisan
elections, and that “this difference is not statistically significant (p
= 0.791).” The subset size reproduces exactly, and so do both
percentages, though the sentence attaches them to the wrong ballot
types: the data give 62.1 per cent nonpartisan and 61.3 per cent
partisan. The p-value does not reproduce under any standard test of that
comparison. A regression with HC2 errors gives 0.852, a chi-squared test
gives 0.919, and Fisher’s exact test, a logit and a t test all land near
0.85. No deposited or recovered script computes this quantity, so there
is no code to inspect. The stated conclusion, that the difference is not
significant, is unaffected either way: 0.791 and 0.85 lead to the same
reading.

**The chi-squared p-value is not a fixed number.** The recovered script
calls `chisq.test(simulate.p.value = TRUE)` and sets no seed, so its
p-value is a Monte Carlo draw. Over 500 replications of that same call
the p-value runs from 5^{-4} to 0.004, and 24 per cent of draws round to
the published 0.002. The published value is a perfectly ordinary draw
from the archive’s own procedure, not a discrepancy. The asymptotic
p-value, which is exact, is 7.44^{-4}.

**The correlation of 0.95 depends on an inconsistency inside the
archive.** `yougov_replication.R` weights the YouGov main-effects models
with the survey weights. `compare_samples_replication.R`, which produces
the correlation, refits the same four models without them. The rewrite
keeps the archive’s unweighted specification, which is what the
published 0.95 requires: weighting those models instead gives 0.9184,
which rounds to 0.92.

------------------------------------------------------------------------

## Original Archive Reproducibility

**Archive source**: Harvard Dataverse, DOI 10.7910/DVN/WSUHI3, version
1.0, ten files.

| File | Status | Issue |
|:---|:---|:---|
| mayors_source.R | Runs | Helper functions; sourced by every script |
| mturk_replication.R | Runs | load() path is mis-cased and would fail on a case-sensitive filesystem; geom_errorbarh() deprecated |
| yougov_replication.R | FAILS | load(‘yougov_replication.rdata’): the deposit contains yougov_replication.xlsx, an RData binary under the wrong extension |
| compare_samples_replication.R | FAILS | Same missing file name |
| observational_replication.R | ABSENT | Listed in the archive README; not deposited. Recovered from the authors |
| observational_mayors_replication.rdata | ABSENT | Listed in the archive README; not deposited. Recovered from the authors |
| observational_codebook.txt | ABSENT | Listed in the archive README; not deposited |
| CSV copies of the three datasets | ABSENT | Listed in the archive README; not deposited |

Original archive check (current R environment)

**The extension anomaly is visible at the Dataverse level, not just in
the download.** The dataset API reports `originalFileName` as
`yougov_replication.xlsx` for that file, and Dataverse ingested it into
a tabular representation named `yougov_replication.tab`. Whatever the
upload looked like, the deposited bytes are an RData file and the name
has never matched them. `download_original.R` writes the file under the
deposited name and `maintained/helpers.R` loads it under that name,
because renaming a deposited file inside a reproduction is how a defect
stops being visible to the next reader.

**What the archive computes but the appendix does not print.** Each of
the two conjoint scripts contains seven figure blocks. Four correspond
to published figures. The remaining three per script build a
valence-index analysis, a policy-index analysis and a satisficing
analysis, and each script also assembles regression tables it labels
D.3, D.5 and so on. The published online appendix has sections A, B and
C, no section D, and no valence or policy figures. The paper’s
Discussion cites “Appendix C.2” for the policy-goal results and
“Appendix C.3” for the satisficing results; the appendix as published
has neither of those subsections, and its satisficing figures are
numbered B.1 and B.2. The online appendix is also dated June 2016,
carries a different subtitle from the article, and refers to the
main-text conjoint figures as Figures 1 and 2 where the article numbers
them 3 and 4. It is an earlier draft of the appendix, published
alongside a later draft of the paper.

**Additional patterns** (warnings or fragility, not errors):

- `geom_errorbarh()`, deprecated in ggplot2 4.0.0.
- `position_dodgev()` from `ggstance`, reached through `coefplot`, which
  the scripts install from GitHub with the comment “it appears that we
  need version \> 1.2.4.9000.”
- `gather` / `spread` throughout.
- `rm(list = ls())` at the top of every script.
- The difference-panel coefficients are selected by hardcoded row index
  (`fit_3_df[19:33, ]`, `[22:39, ]`, `[19:35, ]`, `[22:41, ]`, four
  different windows), and their labels are then overwritten by
  assignment from another model’s row names. Adding a level to any
  attribute silently mislabels the entire panel.
- `cl()` recomputes the cluster vector from the unfiltered data, so
  wherever the outcome has missing values the script has to pass
  `filter(..., !is.na(comp))` by hand. It does, for the competence
  figures. Nothing enforces it.

------------------------------------------------------------------------

## Errata

The rewrite corrects no analytical error, because none of the
discrepancies above is one. The three published numbers that do not
reproduce are a transposition of two labels in one sentence, a p-value
with no surviving code behind it, and a range stated more tightly than
the estimates support. All three are recorded in the ground truth with
`match = 0` and described in the Summary; none affects a conclusion.

------------------------------------------------------------------------

## Ground Truth Verification

| table_figure | claim | value_script | value_paper | match | value_rewrite | match_rewrite |
|:---|:---|---:|---:|---:|---:|---:|
| Table 1 | No previous political experience, nonpartisan N | 163.0000 | 163.000 | 1 | 163.0000 | 1 |
| Table 1 | No previous political experience, nonpartisan % | 21.0000 | 21.000 | 1 | 21.0000 | 1 |
| Table 1 | No previous political experience, partisan N | 72.0000 | 72.000 | 1 | 72.0000 | 1 |
| Table 1 | No previous political experience, partisan % | 30.0000 | 30.000 | 1 | 30.0000 | 1 |
| Table 1 | City legislator, nonpartisan N | 216.0000 | 216.000 | 1 | 216.0000 | 1 |
| Table 1 | City legislator, nonpartisan % | 28.0000 | 28.000 | 1 | 28.0000 | 1 |
| Table 1 | City legislator, partisan N | 39.0000 | 39.000 | 1 | 39.0000 | 1 |
| Table 1 | City legislator, partisan % | 16.0000 | 16.000 | 1 | 16.0000 | 1 |
| Table 1 | County legislator, nonpartisan N | 13.0000 | 13.000 | 1 | 13.0000 | 1 |
| Table 1 | County legislator, nonpartisan % | 2.0000 | 2.000 | 1 | 2.0000 | 1 |
| Table 1 | County legislator, partisan N | 3.0000 | 3.000 | 1 | 3.0000 | 1 |
| Table 1 | County legislator, partisan % | 1.0000 | 1.000 | 1 | 1.0000 | 1 |
| Table 1 | State legislator, nonpartisan N | 37.0000 | 37.000 | 1 | 37.0000 | 1 |
| Table 1 | State legislator, nonpartisan % | 5.0000 | 5.000 | 1 | 5.0000 | 1 |
| Table 1 | State legislator, partisan N | 18.0000 | 18.000 | 1 | 18.0000 | 1 |
| Table 1 | State legislator, partisan % | 8.0000 | 8.000 | 1 | 8.0000 | 1 |
| Table 1 | US legislator, nonpartisan N | 5.0000 | 5.000 | 1 | 5.0000 | 1 |
| Table 1 | US legislator, nonpartisan % | 1.0000 | 1.000 | 1 | 1.0000 | 1 |
| Table 1 | US legislator, partisan N | 4.0000 | 4.000 | 1 | 4.0000 | 1 |
| Table 1 | US legislator, partisan % | 2.0000 | 2.000 | 1 | 2.0000 | 1 |
| Table 1 | Mayor, nonpartisan N | 338.0000 | 338.000 | 1 | 338.0000 | 1 |
| Table 1 | Mayor, nonpartisan % | 44.0000 | 44.000 | 1 | 44.0000 | 1 |
| Table 1 | Mayor, partisan N | 102.0000 | 102.000 | 1 | 102.0000 | 1 |
| Table 1 | Mayor, partisan % | 43.0000 | 43.000 | 1 | 43.0000 | 1 |
| Table 1 | Total, nonpartisan N | 772.0000 | 772.000 | 1 | 772.0000 | 1 |
| Table 1 | Total, nonpartisan % | 100.0000 | 100.000 | 1 | 100.0000 | 1 |
| Table 1 | Total, partisan N | 238.0000 | 238.000 | 1 | 238.0000 | 1 |
| Table 1 | Total, partisan % | 100.0000 | 100.000 | 1 | 100.0000 | 1 |
| Table 1 | Chi-squared statistic | 21.1961 | 21.200 | 1 | 21.1961 | 1 |
| Table 1 | Chi-squared p-value | 0.0015 | 0.002 | 1 | 0.0015 | 1 |
| Text, p. 5 | Elections in which the candidates’ experience differs | 779.0000 | 779.000 | 1 | 779.0000 | 1 |
| Text, p. 5 | More experienced candidate wins, partisan (%) | 61.2903 | 62.000 | 0 | 61.2903 | 0 |
| Text, p. 5 | More experienced candidate wins, nonpartisan (%) | 62.0573 | 61.000 | 0 | 62.0573 | 0 |
| Text, p. 5 | p-value on the partisan/nonpartisan difference | 0.8516 | 0.791 | 0 | 0.8516 | 0 |
| Text, p. 5 | Attorneys or business executives, partisan (%) | NA | 63.000 | NA | NA | NA |
| Text, p. 5 | Attorneys or business executives, nonpartisan (%) | NA | 48.000 | NA | NA | NA |
| Table A.1 | MTurk N | 1204.0000 | 1204.000 | 1 | 1204.0000 | 1 |
| Table A.1 | YouGov N | 1200.0000 | 1200.000 | 1 | 1200.0000 | 1 |
| Table A.1 | MTurk Democrat share | 0.5810 | 0.581 | 1 | 0.5810 | 1 |
| Table A.1 | MTurk Independent share | 0.1640 | 0.164 | 1 | 0.1640 | 1 |
| Table A.1 | MTurk Republican share | 0.2540 | 0.254 | 1 | 0.2540 | 1 |
| Table A.1 | YouGov Democrat share (weighted) | 0.3850 | 0.385 | 1 | 0.3850 | 1 |
| Table A.1 | YouGov Independent share (weighted) | 0.2700 | 0.270 | 1 | 0.2700 | 1 |
| Table A.1 | YouGov Republican share (weighted) | 0.3460 | 0.346 | 1 | 0.3460 | 1 |
| Table A.1 | Respondent race, gender, ideology, education and age panels | NA | NA | NA | NA | NA |
| Discussion | Correlation of MTurk and YouGov estimates | 0.9494 | 0.950 | 1 | 0.9494 | 1 |
| Figure 3 | Political experience, MTurk nonpartisan, smallest effect (pp) | 22.6531 | 25.000 | 0 | 22.6531 | 0 |
| Figure 3 | Political experience, MTurk nonpartisan, largest effect (pp) | 31.9673 | 30.000 | 0 | 31.9673 | 0 |
| Figure 3 | Political experience, nonpartisan minus partisan, mean (pp) | 9.8941 | 10.000 | 1 | 9.8941 | 1 |
| Figures 3 to 8, B.1, B.2, C.3, C.4 | All plotted coefficients and standard errors | NA | NA | NA | NA | NA |

Ground truth verification (50 rows)

**Summary**: 41 of 46 verifiable claims match the published values; 5 do
not. `ground_truth/build_ground_truth.R` rebuilds this table from
`maintained/output/` at the end of every run. The only numbers typed
into that script are the published values themselves, which serve as
comparison targets and are never inputs to a computation.

------------------------------------------------------------------------

## Maintained Rewrite

The rewrite lives in `maintained/`: a shared `helpers.R` and fourteen
scripts, one per published table or figure plus two for in-text
quantities.

| Script | Output |
|:---|:---|
| helpers.R | Packages, both datasets, the estimation and plotting helpers |
| table_1_observational_experience.R | output/table_1_observational_experience.csv, output/text_observational_chisq.csv |
| table_a1_party_identification.R | output/table_a1_party_identification.csv |
| figure_3_mturk_main_candidate_pref.R | output/figure_3_mturk_main_candidate_pref.{pdf,png,csv} |
| figure_4_yougov_main_candidate_pref.R | output/figure_4_yougov_main_candidate_pref.{pdf,png,csv} |
| figure_5_mturk_het_fx_candidate_pref.R | output/figure_5_mturk_het_fx_candidate_pref.{pdf,png,csv} |
| figure_6_yougov_het_fx_candidate_pref.R | output/figure_6_yougov_het_fx_candidate_pref.{pdf,png,csv} |
| figure_7_mturk_het_fx_competence.R | output/figure_7_mturk_het_fx_competence.{pdf,png,csv} |
| figure_8_yougov_het_fx_competence.R | output/figure_8_yougov_het_fx_competence.{pdf,png,csv} |
| figure_b1_mturk_satisficing.R | output/figure_b1_mturk_satisficing.{pdf,png,csv} |
| figure_b2_yougov_satisficing.R | output/figure_b2_yougov_satisficing.{pdf,png,csv} |
| figure_c3_mturk_main_competence.R | output/figure_c3_mturk_main_competence.{pdf,png,csv} |
| figure_c4_yougov_main_competence.R | output/figure_c4_yougov_main_competence.{pdf,png,csv} |
| text_observational_experience_advantage.R | output/text_observational_experience_advantage.csv |
| text_mturk_yougov_correlation.R | output/text_mturk_yougov_correlation.{csv,pdf,png} |

Maintained rewrite scripts

**Key substitutions**:

| Original | Rewrite |
|:---|:---|
| rm(list = ls()) | removed |
| library() in each script | source(helpers.R); all packages in helpers.R |
| custom cl() over sandwich and lmtest | lm_robust(clusters = , se_type = ‘stata’), identical to 1e-15 |
| coefficient rows selected by index | filter(str_detect(term, ‘:nonpartisan\$’)) |
| labels reassigned from another model’s rownames | labels derived from each model’s own terms |
| position_dodgev() from ggstance via coefplot | position_dodge(width = 0.5) |
| geom_errorbarh(height = 0) | geom_linerange() |
| geom_segment() for confidence bars | geom_linerange() |
| gather / spread | pivot_longer / pivot_wider |
| magrittr pipe | native pipe |
| figures held only as in-memory R objects | written to output/ as PDF, PNG and CSV |
| load(‘yougov_replication.rdata’) | load(‘yougov_replication.xlsx’), the deposited name |

Deprecated patterns and replacements

**The standard error substitution.** The archive’s `cl()` function
scales the CR0 meat by `(M / (M - 1)) * ((N - 1) / (N - K))`, which is
what `estimatr::lm_robust(se_type = "stata")` computes. The two agree to
1e-15 on every model in the paper. An earlier version of this rewrite
asked for `se_type = "CR1S"`, the name estimatr used for the same
estimator until version 1.0.6 retired it; that name now raises an error,
which is why every figure script here names the estimator “stata”.

**The weighting decisions are surfaced, not defaulted.** The archive
applies the YouGov survey weights to the main-effects figures (4 and
C.4) and to the satisficing figure (B.2), but not to the
heterogeneous-effects figures (6 and 8) and not to the four models
behind the correlation in the Discussion. The rewrite reproduces each
figure as the archive specifies it, and `election_type_panels()` takes
`weighted` as a required argument with no default so the choice is
visible at every call site. Weighting the heterogeneous-effects models
would move individual estimates by up to 0.04 and the reported
correlation from 0.95 to 0.92, which is a change to the analysis rather
than a repair to it.

**What the rewrite adds.** The published appendix figures B.1 and B.2,
which the archive computes and no earlier rewrite covered, and the one
panel of Table A.1 the deposit can support. The in-text observational
comparison on page 5 has no code anywhere in the archive or the
recovered files; it is reconstructed here from the recovered data. Every
figure now writes a CSV of the plotted estimates alongside the image,
which is what makes a rerun diffable.

**What the rewrite leaves alone.** The confidence bars are drawn at plus
or minus 1.96 standard errors, as the archive draws them, rather than at
a t quantile on the cluster-adjusted degrees of freedom. The
valence-index and policy-index analyses the archive computes are not
rewritten, since neither appears in the published paper or appendix. The
unweighted YouGov specifications stay unweighted.

------------------------------------------------------------------------

## Figure Verification

Every plotted coefficient and standard error in the ten conjoint figures
was compared against the archive’s own `lm()` plus `cl()` output, term
by term and panel by panel: 729 pairs, agreeing to within 4e-13. Two of
the figures follow.

<img src="maintained/output/figure_3_mturk_main_candidate_pref.png"
style="width:95.0%"
alt="Figure 3 reproduction. MTurk main analysis, candidate preference. Columns are nonpartisan elections, partisan elections, and the difference between them; rows are attribute groups. Political experience carries visibly more weight when the party label is withheld." />

<img src="maintained/output/figure_5_mturk_het_fx_candidate_pref.png"
style="width:95.0%"
alt="Figure 5 reproduction. MTurk heterogeneous effects on candidate preference, Democratic respondents in blue and Republican respondents in red." />

<img src="maintained/output/figure_b1_mturk_satisficing.png"
style="width:95.0%"
alt="Appendix Figure B.1 reproduction, the satisficing check. Partisan elections only, split by whether the two candidates share a party. Both panels display six attributes, so the number of attributes is held fixed and only the informativeness of the party label varies." />

<img src="maintained/output/text_mturk_yougov_correlation.png"
style="width:70.0%"
alt="The Discussion’s correlation of 0.95, plotted. Each point is one attribute level’s effect on candidate preference, estimated on MTurk and on YouGov, with 95 per cent intervals on both axes." />

------------------------------------------------------------------------

## Maintained Rewrite Verification

| table_figure | claim | value_paper | value_rewrite | match_rewrite |
|:---|:---|---:|---:|---:|
| Table 1 | No previous political experience, nonpartisan N | 163.000 | 163.0000 | 1 |
| Table 1 | No previous political experience, nonpartisan % | 21.000 | 21.0000 | 1 |
| Table 1 | No previous political experience, partisan N | 72.000 | 72.0000 | 1 |
| Table 1 | No previous political experience, partisan % | 30.000 | 30.0000 | 1 |
| Table 1 | City legislator, nonpartisan N | 216.000 | 216.0000 | 1 |
| Table 1 | City legislator, nonpartisan % | 28.000 | 28.0000 | 1 |
| Table 1 | City legislator, partisan N | 39.000 | 39.0000 | 1 |
| Table 1 | City legislator, partisan % | 16.000 | 16.0000 | 1 |
| Table 1 | County legislator, nonpartisan N | 13.000 | 13.0000 | 1 |
| Table 1 | County legislator, nonpartisan % | 2.000 | 2.0000 | 1 |
| Table 1 | County legislator, partisan N | 3.000 | 3.0000 | 1 |
| Table 1 | County legislator, partisan % | 1.000 | 1.0000 | 1 |
| Table 1 | State legislator, nonpartisan N | 37.000 | 37.0000 | 1 |
| Table 1 | State legislator, nonpartisan % | 5.000 | 5.0000 | 1 |
| Table 1 | State legislator, partisan N | 18.000 | 18.0000 | 1 |
| Table 1 | State legislator, partisan % | 8.000 | 8.0000 | 1 |
| Table 1 | US legislator, nonpartisan N | 5.000 | 5.0000 | 1 |
| Table 1 | US legislator, nonpartisan % | 1.000 | 1.0000 | 1 |
| Table 1 | US legislator, partisan N | 4.000 | 4.0000 | 1 |
| Table 1 | US legislator, partisan % | 2.000 | 2.0000 | 1 |
| Table 1 | Mayor, nonpartisan N | 338.000 | 338.0000 | 1 |
| Table 1 | Mayor, nonpartisan % | 44.000 | 44.0000 | 1 |
| Table 1 | Mayor, partisan N | 102.000 | 102.0000 | 1 |
| Table 1 | Mayor, partisan % | 43.000 | 43.0000 | 1 |
| Table 1 | Total, nonpartisan N | 772.000 | 772.0000 | 1 |
| Table 1 | Total, nonpartisan % | 100.000 | 100.0000 | 1 |
| Table 1 | Total, partisan N | 238.000 | 238.0000 | 1 |
| Table 1 | Total, partisan % | 100.000 | 100.0000 | 1 |
| Table 1 | Chi-squared statistic | 21.200 | 21.1961 | 1 |
| Table 1 | Chi-squared p-value | 0.002 | 0.0015 | 1 |
| Text, p. 5 | Elections in which the candidates’ experience differs | 779.000 | 779.0000 | 1 |
| Text, p. 5 | More experienced candidate wins, partisan (%) | 62.000 | 61.2903 | 0 |
| Text, p. 5 | More experienced candidate wins, nonpartisan (%) | 61.000 | 62.0573 | 0 |
| Text, p. 5 | p-value on the partisan/nonpartisan difference | 0.791 | 0.8516 | 0 |
| Table A.1 | MTurk N | 1204.000 | 1204.0000 | 1 |
| Table A.1 | YouGov N | 1200.000 | 1200.0000 | 1 |
| Table A.1 | MTurk Democrat share | 0.581 | 0.5810 | 1 |
| Table A.1 | MTurk Independent share | 0.164 | 0.1640 | 1 |
| Table A.1 | MTurk Republican share | 0.254 | 0.2540 | 1 |
| Table A.1 | YouGov Democrat share (weighted) | 0.385 | 0.3850 | 1 |
| Table A.1 | YouGov Independent share (weighted) | 0.270 | 0.2700 | 1 |
| Table A.1 | YouGov Republican share (weighted) | 0.346 | 0.3460 | 1 |
| Discussion | Correlation of MTurk and YouGov estimates | 0.950 | 0.9494 | 1 |
| Figure 3 | Political experience, MTurk nonpartisan, smallest effect (pp) | 25.000 | 22.6531 | 0 |
| Figure 3 | Political experience, MTurk nonpartisan, largest effect (pp) | 30.000 | 31.9673 | 0 |
| Figure 3 | Political experience, nonpartisan minus partisan, mean (pp) | 10.000 | 9.8941 | 1 |

Rewrite verification: 41 of 46 claims match published values

Two full runs of `run_all.R` produce byte-identical CSV and PNG output.
Only the PDF figures differ between runs, because a PDF records the time
it was written.

------------------------------------------------------------------------

## R Environment

| Package    | Version |
|:-----------|:--------|
| tidyverse  | 2.0.0   |
| estimatr   | 1.0.6   |
| knitr      | 1.51    |
| kableExtra | 1.4.0   |
| here       | 1.0.2   |

Key package versions

R version: R version 4.6.0 (2026-04-24)
