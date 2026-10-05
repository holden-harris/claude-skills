# Verification protocols

Read this when Phase 4 (smoke, then baseline) and Phase 8 (verify) begin, and in the degraded mode whenever a run step is handed to the analyst. Everything measured here is written into Doc B §9 (as-found in Phase 4, as-left in Phase 8) and cited from the evidence rows of Doc C §9, then committed as `record` before any code that relies on it. The worked examples are lifted from the GFISHER audit (WFS-FEM/GFISHER issue #2, `docs/issue2-review-gfisher-repo-plan.md`) and the RedTideMaps hull fix (issue #3).

Two rules hold throughout. Numbers go in tables with their cause next to them. Nothing is written that was not observed: a run time, exit code or checksum that has not arrived reads "pending: run on the analyst's machine".

## Smoke protocol (seconds, not minutes)

Run before the baseline and again after any change to the entry point. Each check takes seconds, so a failure is found before a 16-minute run, not after.

| Check | How | Pass | Fail |
|---|---|---|---|
| Root anchor | The driver's anchor file (`<name>.Rproj`, or whatever the code tests) is in the repository root; run the driver from a wrong directory and from the root | Wrong directory stops with a readable message; root proceeds | Driver assumes `getwd()` is the root (a P-finding); record it, and fix only after the baseline unless it blocks every run |
| Every file parses | `Rscript <skill>/scripts/static_sweep.R <repo>`; it parses each source file without executing anything | Zero parse errors | File and line of each error, as a B-finding in Doc C §2 |
| Packages | The repository's own package check if it has one, else `requireNamespace()` over the declared list | All present, or the exact `install.packages(c(...))` line printed | Missing packages listed with the file that needs them (a P-finding when undeclared) |
| Inputs present | The repository's input manifest if it has one, else the paths the driver reads, checked with `file.exists()` | Every required input found | A table of what is missing and where to get it; a check that only fails deep inside a stage is itself a finding |

A smoke pass reads: anchor OK, `n` files parsed with 0 errors, packages OK, inputs OK. A smoke fail is one line per problem, each a row in Doc C §2 with a finding ID.

## Baseline protocol

Run the unmodified code the way the author runs it. The only edits allowed are the ones that let it run at all (a path pointed at the analyst's copy of an input), and the baseline notes say exactly which lines were changed.

1. `Rscript <skill>/scripts/snapshot_md5.R snapshot <output dir> <stamp>/md5_committed.csv` on the tracked outputs before the run, so the committed deliverables are on record.
2. `Rscript <skill>/scripts/run_logged.R <driver.R> --out <stamp>/run`: environment header, full log, exit status and wall time, written outside the repository.
3. `snapshot_md5.R snapshot` again after the run, then `snapshot_md5.R compare <before> <after> --md` for the comparison table.
4. Copy the outputs outside the repository, next to the log and the two CSVs; `../<repo>-audit/<stamp>/` is a good default because git never sees it and the Phase 8 runs are compared against it later.
5. `Rscript <skill>/scripts/session_capture.R <pkg ...>` for the environment table.

Write Doc B §9 (as-found) with: an environment line (machine, OS, language version, the packages that matter, the commit, the exact edits made to run); a bold result line (exit code, wall time); a per-stage table (`Stage | Ran | Log evidence`) quoting the log; warnings, each tied to a finding ID; the MD5 comparison table (`Output group | Identical | Changed | Cause`) with every changed group explained or given a finding ID to investigate; and where the copy lives. Note line-ending-only differences separately from real changes, since they point at an editor or `core.autocrlf`, not at the code.

From GFISHER section 4.1, verbatim, as the example of all of this:

> Run on 1 Oct 2026 on Holden's machine (Windows 11, R 4.5.1, raster 3.6-32, terra 1.8-80,
> sf 1.0-21) with `Rscript` on a copy of the driver at commit `b544821` in which exactly two
> lines were changed: `dir.dbseabed` pointed at `EcospaceBasemap/data/dbseabed` and
> `file.seagrass` at `EcospaceBasemap/output/5min/habitat/seagrass/seagrass_coverage_Seagrass_Statewide_5min.asc`.
> `data/April2026` is a Windows directory junction to the OneDrive copy of Dave's folder, so
> the files are not duplicated and git ignores the path. Dave's OneDrive Ecospace maps tree is
> not synced to Holden's machine and was not needed.
>
> **Result: all stages ran to completion. Exit code 0. Wall time 15 min 39 s.**

| Stage | Ran | Log evidence |
|---|---|---|
| 1 basemaps | yes | 309,348 microgrids, 141,053 habitat polygons; 1,495 of 3,838 water cells mapped; QC row sum min 1 max 1; wrote 9 layers |
| 2 video dataset | yes | "Dropping 52471 record(s) with missing modnumber, maxn, or coordinates" |
| 3 MaxN maps | yes | 19 group rasters + PDF written |
| 4a selection ratios | yes | red-grouper-1 pooled with red-grouper-0 (3 cells with MaxN>0); 4 files written |
| 4b site affinities | yes | 4 files written |
| 4c substrate affinities | yes | 5 files written |

> Warnings only: `rm(.SavedPlots)` object not found (P3); packages built under a newer R
> patch release; one GDAL `organizePolygons()` performance message while reading the
> geodatabase. `windows(record=T)` ran under `Rscript` on Windows without error.
>
> **Comparison with the committed outputs** (MD5 of all 54 tracked `.asc`/`.csv` files
> before and after; no line-ending-only differences were found):

| Output group | Identical | Changed | Cause |
|---|---|---|---|
| `output/basemaps/15min/` (10 files) | 10 | 0 | not regenerated at `res = 5` |
| `output/basemaps/5min/` (10 files) | 0 | 10 | seagrass input only, see below |
| `output/maps/.../maxn/mice/` (19 rasters) | 8 | 11 | unseeded length draws (R1): the 8 unchanged are the single-stanza groups plus red-grouper-0; the 11 changed are the gag and red grouper age stanzas |
| `output/affinity_selratio_mice/` (5 files) | 0 | 5 | downstream of the above, plus the effort raster (R5) |
| `output/affinity_site_mice/`, `affinity_substrate_mice/` (9 files) | 0 | 9 | downstream of stage 2 |
| `output/affinity_selratio/` (untagged, 5 files) | 5 | 0 | stale folder, not written by current code (R4) |

Every row has a cause. The two that did not have one at first ("seagrass input only, see below" and "the effort raster (R5)") each got a paragraph, and one of them a new finding; that is the next section.

## Reading a comparison

A changed MD5 says only that bytes differ. Root-cause it before writing the cause column: open both files, find which cells, rows or columns differ, and test one explanation at a time until the difference is fully accounted for. GFISHER's basemap paragraph is the shape to aim for:

> **Basemaps: the seagrass raster is the only source of difference.** The 45 water cells
> where the SGR layer differs are the only cells where any layer differs; in the other 3,793
> water cells all nine layers are bit-identical. In those 45 cells the reef and rock layers
> scale by exactly `(1 - SGR_new) / (1 - SGR_old)` (max deviation 7e-8), which is the sum-to-1
> normalisation. Largest absolute differences: UNC 0.080, SGR 0.080, NL 0.006, others below
> 1e-3. The committed SGR mean is 0.01218; ours 0.01236.

The pattern: name the single source, show that nothing else moved (the 3,793 identical cells), show that the moved cells move by the amount the method predicts (the normalisation factor), and give the largest differences with units. When the cause is an input the audit does not have, end with an **ask of the author** that is concrete and small: "add the two files (about 44 KB each) to `data/seagrass/` so the basemaps can be reproduced exactly." When it is a new finding (GFISHER R5, an effort raster whose header carried a rounded cell size from an older template), it gets an ID in Doc C §2 and a sentence saying whether code must change (there, no: the committed file is regenerated from the current template and a cheap guard is added).

Keep the copy of the baseline outputs outside the repository with the MD5 CSVs and the full log, and write the path into Doc B §9. The Phase 8 runs are compared against this copy, and it is the only record of the author's committed outputs once `outputs` has landed.

## Same-seed and cross-seed test

When the S lens finds randomness, or the baseline comparison shows outputs that move between runs, rerun the smallest set of stages that contains the draw three times: seed A, seed A again, seed B. Same-seed proves determinism; cross-seed shows what the seed changes and, as important, what it does not. Write the results as an invariants table. From GFISHER 4.1b, verbatim:

| Test | Result |
|---|---|
| Same seed twice | Stage 2 tables `identical()`; all 19 rasters byte-identical |
| Grand total MaxN, seed 1 vs seed 2 | 1,043,543 in both |
| Per-species total MaxN | identical for every species |
| Per-station x species total MaxN (60,374 rows) | 0 rows differ |
| Union of occupied cells per species | gag 458 cells, red grouper 747 cells, identical sets |
| 7 single-stanza maps | identical across seeds |
| Rows with a missing group number | 17,215 rows (MaxN 139,311) across 160 taxa, identical across seeds; these are taxa outside the model groups (e.g. `baitfish unk`, `pagrus pagrus`), not multistanza fish. No gag or red grouper record lacks a group |
| Function's own "counts did not sum back" check | silent for both seeds |

"The seed changes exactly one thing" is the conclusion this table earns: every total and every set is identical across seeds, and only the split among stanzas moves, through the two named calls (`rtruncnorm`, `sample.int`). A row that is neither identical nor explained by the draw is a bug, not a seed effect.

Then the warning that belongs in Doc B §6 and Doc A §7: **a fixed seed makes the outputs reproducible but not less noisy.** One draw is one realisation. GFISHER's per-cell differences between seeds were 13 to 229 cells per stanza map with correlations from 0.14 to 0.98, and the author's committed maps against the baseline showed the same pattern, which is how you know the two are draws from the same process rather than different code. If the drawn quantity feeds a later stage, whether one realisation is acceptable is a methods question for the author, not something `set.seed()` answers.

## Seed-sensitivity experiment

When the cross-seed test shows the draw matters downstream, the next step is an experiment, not a fix. GFISHER 4.1c ran ten seeds through stages 2, 3 and 4a (1.7 min per seed, outputs outside the repository, a notes log and per-seed tables kept with them) and summarised 96 rows (11 stanza groups x 8 habitat layers). Its design transfers:

- **Control groups first.** The seven single-stanza groups and red grouper 0 had range 0 across all ten seeds, so whatever moved was the draw alone. Without a control, a spread could be anything.
- **A reading scale the method already provides.** For each group and layer, "seed range" (the spread of the estimate across seeds) is divided by "bootstrap width" (the 95% interval the method already reports). A ratio below 1 means the seed adds less uncertainty than the method acknowledges. Across the 96 rows, 88 had a ratio below 1 (median 0.43); the 8 exceptions all belonged to the two sparsest stanzas (red grouper 1 with 10 occupied cells, red grouper 2 with 41), where the "best" habitat changed with the seed.
- **Columns**: `Group | occupied cells | seed range / bootstrap width, median (max) | range of the final quantity | distinct best layers in 10 seeds | rank agreement with seed 1, min Spearman`. Any analysis with a per-group estimate and an interval can fill this shape.
- **Options for the author, each deterministic**, with no recommendation enforced: average over many seeds (the expected composition), raise the pooling threshold so sparse groups borrow from a neighbour, or assign expected fractions instead of drawing.

The experiment informs a methods decision (Doc C §8, a sub-issue, and where the profile has them a decision issue). It is never acted on silently: the arithmetic stays as it is so the outputs remain comparable, and the experiment script, committed with the documents, takes its paths from the config and reproduces the table it is cited for.

## Fresh-clone tests (Phase 8)

Three tests, in this order, on the same commit. From GFISHER 4.1d.

1. **Fresh clone, no data.** `git clone -b N-slug <remote> <temp dir>`, then the command-line entry point. It must fail fast with a MISSING table that names each absent input and where to get it, before any slow work. GFISHER's first attempt instead tried to download the dbSEABED grids from a server that did not respond (new finding R6); after the fix the failed download was caught in about 20 s, explained in one line, and listed as MISSING with the fallback instruction. A no-data run that fails deep inside a stage, or hangs on a network call, fails this test.
2. **Fresh clone, data placed, minimal local config.** Only the documented inputs copied or pointed at, and a local config of a few lines (GFISHER: three). Full command-line run; must exit 0. Record the wall time with its conditions (GFISHER: 56 min with two other R jobs running, 16 min alone).
3. **Independent interactive run**, the way the author works: same commit, opened from the project file, `source()`, the author-style input layout (GFISHER: a directory junction, no config overrides). All stages must complete.

Then the byte-identity statement, which is the point of running all three:

> **Result: the two runs are byte-identical in all 51 output files** (ASCII grids and CSVs,
> compared line by line), despite different invocation (Rscript vs RStudio), different input
> paths (OneDrive vs junction) and different copies of the public inputs (EcospaceBasemap vs
> shipped). The stage 1 basemaps also equal the 1 Oct baseline run exactly, and the 19 MaxN maps
> equal the seed-1 maps from the issue #5 experiment exactly.

Finally the regenerated-vs-committed table, where every row cites a finding ID or a decision number. It is the body of the `outputs` commit and the author's reading guide to the diff. GFISHER 4.1d, verbatim:

| Output | Change | Cause |
|---|---|---|
| 5-min basemaps, 9 layers + QC | 45 cells; SGR and UNC by up to 0.08, NL 0.006, others < 1e-3 | seagrass raster now the EcospaceBasemap one (decision 9) |
| 15-min basemaps | unchanged | not regenerated (no 15-min seagrass) |
| MaxN maps | 8 identical, 11 stanza maps differ | one seeded draw replaces the author's unseeded one (R1) |
| Survey effort raster | 14 cells, same 14,613 stations, header now the exact 1/12 cell size | template (R5) |
| 4a affinities, single-stanza groups | A changes by at most 0.002 | effort raster and seagrass cells |
| 4a affinities, stanza groups | A changes by up to 0.69 (red grouper 1), 0.44 (gag 0), 0.45 (red grouper 3), 0.10 to 0.32 elsewhere | one draw vs another; the sparse stanzas are the sensitive ones (issue #5) |
| 4b, 4c affinities | regenerated from the seeded stage 2 table | as above |

The acceptance checklist that these tests tick (Doc C §9) points at the section holding each piece of evidence, and its last box is the author's. GFISHER §7, verbatim:

> - [x] `Rscript "process GFISHER data.R"` from a fresh clone with only `config.local.R`
>       added completes without error on Holden's machine (4.1d; exit code 0).
> - [x] Run from the wrong folder stops with the anchor message; missing input stops before
>       stage 1 with a table naming the file and where to get it (4.1d; smoke tests in 4.1).
> - [x] `git grep -nE "dchagaris|OneDrive"` over `*.R` matches only comments in
>       `config.local.example.R`. `git grep -n "windows("` matches nothing. (Verified before the
>       final commits; see the PR checklist.)
> - [x] Basemaps regenerate identically given the same inputs: the fresh-clone run, Holden's
>       RStudio run and the 1 Oct baseline agree byte for byte (4.1d). They differ from the
>       author's committed files only in the 45 seagrass cells (decision 9).
> - [x] Stages 2 and 3 are deterministic: same seed gives identical MaxN rasters (4.1b), and
>       two independent runs at seed 1 are identical (4.1d).
> - [x] `git ls-files --cached --ignored --exclude-standard` is empty (housekeeping commit).
> - [x] README and CLAUDE.md describe the four stages, inputs, outputs, and tested environment.
> - [ ] Dave runs the branch with his `config.local.R` and confirms the outputs.

## The run matrix

Doc B §9 (as-left) closes with one row per target. Fill it from the tests above; a cell that has not happened reads "pending". The example rows are GFISHER's; replace them with the audited repository's.

| Target | How run | Inputs | Result | Evidence location |
|---|---|---|---|---|
| Analyst (fresh clone, `Rscript`) | `git clone -b 2-review-gfisher-repo` into a temp folder; `Rscript "process GFISHER data.R"` with a three-line `config.local.R` | FWRI files by path (OneDrive), public grids and seagrass from EcospaceBasemap | exit 0; 56 min with two other R jobs running (16 min alone) | Doc B §9 as-left; `../gfisher-audit/<stamp>/clone/` |
| Author's layout (interactive) | `GFISHER.Rproj` opened in RStudio, `source("process GFISHER data.R")`, no config overrides | `data/April2026` junction; grids and seagrass shipped in `data/` | all stages complete; 51 files byte-identical to the clone run | Doc B §9 as-left; `../gfisher-audit/<stamp>/interactive/` |
| Fresh clone, no data | same clone, inputs absent | none | stops in about 20 s with a MISSING table naming `dbseabed` and the FWRI files | Doc B §9 as-left, smoke paragraph |
| Original author on his machine | his `config.local.R`, his habits | his trees | pending: author's sign-off, last box of Doc C §9 | PR comment when it arrives |

## Convention checks

Run after the last `code` commit and before the Phase 8 `record` commit; paste the commands and their output into Doc B §9 so a reader can rerun them.

| Command | Expected |
|---|---|
| `git grep -nE "[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R'` | Only commented examples match (the local config template's `# dir.data <- "C:/..."` lines); a hit in live code is a P-finding |
| `git grep -n "windows(" -- '*.R'` | Empty; the guarded device call lives in a setup function behind `interactive()` |
| `git ls-files -ci --exclude-standard` | Empty: what is tracked is exactly what is not ignored |
| `git status` | Clean: a run leaves no modified tracked file and no stray untracked file (session files, `Rplots.pdf`, scratch) |

Other languages substitute their own extension in the glob and their own platform-only calls in the second line.

## Timing

Record stage timings from the log in the shape below, so the T lens has something to work from and the README can quote a run time honestly.

| Stage | Wall time | What dominates | Cache or skip candidate |
|---|---|---|---|
| 1 basemaps | 12 min | geodatabase read (309,348 microgrids) | cache the read as `.rds`; skip when the outputs are newer than the inputs |
| 2 video dataset | 1 min | survey CSV joins | no |
| ... | | | |
| Total | 15 min 39 s | | |

Record a run time honestly: say what else was running (GFISHER's 56 versus 16 minutes was two other R jobs, not the code), whether the cache was warm or cold (RedTideMaps' 9 minutes was with cached sdmTMB fits that were not refit), the machine, and whether the time came from the log or from a clock on the wall. A number without those is not evidence.

## The QA-script pattern

A `behavioural` fix needs a script that puts the old and the new code side by side on the same inputs, and the script is committed so the comparison can be rerun. RedTideMaps `scripts/qa/check_hulls_issue3.R` is the model. Its header says what it compares, what it needs, how to run it and what it writes:

```r
#' QA for issue #3: spurious hull polygons in fallback months.
#'
#' Compares the pre-fix fn.buffered_hulls() (k-means clustering) with the
#' working-tree version (single-linkage clustering) for the ten months
#' flagged in issue #3 plus nine control months with real blooms, at
#' link_km = 50 and 75. Also runs a synthetic stopifnot() block (two
#' well-separated clusters must give two footprints; two calls on the same
#' input must give identical polygons).
#'
#' Setup, once: save the pre-fix code from main next to this script. The
#' copy is gitignored (scripts/qa/_*).
#'
#'   git show main:scripts/polygon_clipping_rt.R > scripts/qa/_polygon_clipping_rt_main.R
#'
#' Needs a previous pipeline run (out/5min/sdm/*_filtered.Rdata).
#'
#' Run from the repo root:  Rscript scripts/qa/check_hulls_issue3.R
```

The four parts of the pattern:

1. **Old and new code in separate environments**, so two versions of a function with one name exist at once: `env_old <- new.env(); sys.source(file_old, envir = env_old)`, the same for `env_new`, then `env_old$fn(...)` against `env_new$fn(...)`. The pre-fix file comes from `git show main:<path> > scripts/qa/_<name>_main.R`, and `scripts/qa/_*` is gitignored so the copy never lands in the branch.
2. **A `stopifnot()` block on synthetic input** that encodes what the fix promises, with fixed offsets and no RNG (the script's 3 + 12 points must give two footprints, neither spanning 100 km). From the script, the determinism check:

```r
# Determinism: two calls on the same input give identical polygon lists.
det_a <- file.path(tmp, "det_a"); det_b <- file.path(tmp, "det_b")
dir.create(det_a, showWarnings = FALSE); dir.create(det_b, showWarnings = FALSE)
load(quiet(env_new$fn.buffered_hulls(file_filtered, file_depth, det_a, styr = 1996, enyr = 1999)))
pl_a <- pol_list
load(quiet(env_new$fn.buffered_hulls(file_filtered, file_depth, det_b, styr = 1996, enyr = 1999)))
pl_b <- pol_list
stopifnot(identical(pl_a, pl_b))
cat("determinism (1996-1999, two calls identical()):", identical(pl_a, pl_b), " ... OK\n")
```

   The script then prints what the old code does on the same input (two unseeded calls, `identical()` FALSE), so the reader sees the before as well as the after.

3. **A PDF of before/after panels**, one page per case, flagged cases and controls labelled, with n, area and span in each panel title, so the author can judge the change by eye without running anything.
4. **An MD5 regression check on what must not change.** The RedTideMaps plan (§7 steps 7 to 8, §8) snapshots the deliverables with `tools::md5sum()` before the full run and copies the per-month decision table aside; the acceptance criteria then require that every month not served by the changed code path has the same MD5 as before, that the decision table is identical, and that the number of changed files is reported. That count, with its cause, is the before/after table of the `outputs` commit.

## Cloud hand-off text

In the degraded mode, paste a block like this at pause 4 (baseline) and again in Phase 8 (verification), with the placeholders filled. Until the results come back, Doc B §9 and the evidence rows in Doc C §9 read "pending: run on the analyst's machine", and nothing the block is expected to produce is written as if it had happened.

```
Run this on your machine, then paste back the three items at the end.

Command line (from the repository root):
  mkdir ../<repo>-audit/<stamp>
  Rscript "<skill>/scripts/snapshot_md5.R" snapshot <output dir> ../<repo>-audit/<stamp>/md5_before.csv
  Rscript "<skill>/scripts/run_logged.R" "<driver.R>" --out ../<repo>-audit/<stamp>/run
  Rscript "<skill>/scripts/snapshot_md5.R" snapshot <output dir> ../<repo>-audit/<stamp>/md5_after.csv
  Rscript "<skill>/scripts/snapshot_md5.R" compare ../<repo>-audit/<stamp>/md5_before.csv ../<repo>-audit/<stamp>/md5_after.csv --md
  Rscript "<skill>/scripts/session_capture.R" <pkg ...>

RStudio (open <name>.Rproj first, then in the console; base R only):
  dir.create("../<repo>-audit/<stamp>", recursive = TRUE)
  f <- list.files("<output dir>", recursive = TRUE, full.names = TRUE)
  write.csv(data.frame(file = f, md5 = unname(tools::md5sum(f))), "../<repo>-audit/<stamp>/md5_before.csv", row.names = FALSE)
  t0 <- Sys.time(); source("<driver.R>"); print(Sys.time() - t0)
  f <- list.files("<output dir>", recursive = TRUE, full.names = TRUE)
  write.csv(data.frame(file = f, md5 = unname(tools::md5sum(f))), "../<repo>-audit/<stamp>/md5_after.csv", row.names = FALSE)
  sessionInfo()

Where things land: ../<repo>-audit/<stamp>/ (outside the repository, so git never sees it).
Copy <output dir> into that folder as well once the run has finished.

Paste back:
  1. The log tail: the last 40 lines of ../<repo>-audit/<stamp>/run/*.log (or of the RStudio
     console), plus every line containing "Error" or "Warning", and the exit code and wall time
     from the log footer (or the printed Sys.time() difference).
  2. The environment table from session_capture.R (or the sessionInfo() output).
  3. The two MD5 CSVs, or the compare output if you ran it.

If this skill's scripts are not on your machine, use the RStudio block; it needs only base R.
```

Parse what comes back into Doc B §9 and C; quote the log lines rather than paraphrasing them, and give every changed MD5 a cause or a finding ID exactly as in a local baseline.
