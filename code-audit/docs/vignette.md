# Vignette: a review-only audit of EcospaceBasemap, then the local steps

This is a curated record of one real run of `/code-audit`, made on 6 October 2026 in a cloud Claude Code session that had no R installed, against `WFS-FEM/EcospaceBasemap` at commit `3d97024` (the state after the author's five module commits and the reviewer's portability pull request). It shows what the skill asks, what it writes at each phase, what the analyst says at each pause, and what the local machine does afterwards. Excerpts are verbatim from the documents the run produced, trimmed for length.

The repository is small (one driver, nine function files, 63 functions) and had already been through one review, so this is a realistic second look rather than a first contact.

## 1. The setting, and why review-only first

The analyst asked for a review-only pass: "no GitHub writes, no commits, and R is not installed on this machine, so don't try to run anything. I want the three review documents ... and tell me which findings you would send to Dave rather than fix." Review-only is the right first mode when you want to see what the audit would find before committing to an issue and a branch, and it is the only mode a session without the runtime can complete on its own. The skill detected the WFS-FEM org profile from the remote owner and the degraded mode from the missing runtime.

## 2. Phase 1: the setup interview

The analyst was not available during this run, so the skill stated each question in its transcript and recorded the answer it assumed, then played the result back as Doc C §1. From the transcript:

```
Confirm mode review-only and org profile WFS-FEM? Assumed yes (the task says review-only,
  no GitHub writes, no commits; the remote owner is WFS-FEM).
Analyst's machine (OS, R version)? Unknown; recorded as pending in Doc C §1 and Doc B §2.4
  (Windows and R 4.x assumed from the config example and the README's "R >= 4.4").
What counts as reference outputs? Assumed: the author's legacy grids on his machine, the README
  verification table (:753-769) and the ten docs/img/ figures; no output is tracked
  (recorded as finding R4).
Scope limits? Assumed whole repository; the Python digitising step and the legacy repositories
  out of scope; no arithmetic changes.
Does a GitHub issue exist? Assumed none; none created. PR #1 (merged 2 Oct 2026) is history,
  not an open issue.
```

In a live session each of these is one question, and Pause 1 is the one-paragraph playback: "Review-only, WFS-FEM profile, whole repository, no arithmetic changes, reference outputs are the legacy grids and the README table. Correct?" The analyst's usual reply is one word.

## 3. Phase 2: orientation

The skill read the driver and the function files, found the order of operations (anchor check, source `R/`, attach packages, settings, local config, pull and check inputs, sections 1 to 5), and drafted Doc A §1-5 and Doc B §1-2. The opening of Doc A §1 shows the register the skill aims for: every sentence carries its source, and the three things a user of the outputs must know come first.

> EcospaceBasemap builds the static basemap layers for the West Florida Shelf Ecopath with Ecosim / Ecospace model: a depth grid and its exclusion mask, ten habitat layers that sum to one in every water cell, nine binary management-area grids, eleven binary fleet-port grids and one categorical survey-region grid, all written as ESRI ASCII rasters on a common 5 arc-minute grid of 66 rows by 78 columns ... (README:3-5, 442; `make_WFS_basemaps.R:36-38`). ... Three things a user of the outputs must know. The sum-to-one folder (`habitat/sum1/`) is the Ecospace input; everything else is intermediate or auxiliary (README:698). The artificial reef layers are relief-weighted indices, not proportions, and the relief unit (feet in the source, treated as metres) is unresolved (§5.5, §7). And 85 to 90 percent of the natural reef in the finished basemap is dbSEABED rock redistributed by a stratified rule, not side-scan observation (§5.6, §7).

Doc B §1 opens with the stage table; the "How long" column is honest about what is a claim and what is measured:

```
| Stage (driver section) | What goes in | What comes out | How long | Where in the code |
| 1 depth and exclusion | NOAA ETOPO via marmap::getNOAA.bathy() (live) | depth_5min.asc, excl_5min.asc, one PNG | "seconds, NOAA download" (README:89; claimed) | make_WFS_basemaps.R:64-95 |
| 2.1 seagrass | data/seagrass/GulfwideSAV/, optional data/seagrass/Seagrass_Statewide/ | per-source cover grids and a combined grid, PNGs | "seconds (max)" (README:90; claimed) | R/seagrass_functions.R |
```

Pause 2 is "Is this what the code does?" On this repository the analyst, who had already worked through it, would answer yes; on a repository you have never seen, this is where a wrong idea of the pipeline gets corrected before it costs anything.

## 4. Phase 3: skipped, and what it would have done

Review-only skips the GitHub scaffold. Doc C's status block records that explicitly, and the resume rule reads it on the next invocation:

```
Issue: none (review-only)        Branch: none (tree at claude/pensive-feynman-bvssdu, identical to main)        Pull request: none
Mode: review-only, degraded (no R runtime, no GitHub writes)        Org profile: WFS-FEM
Reviewer: Holden Harris, with Claude Code        Original author: David Chagaris
Line numbers refer to commit: 3d97024 (main, 2 Oct 2026, "Merge pull request #1 from WFS-FEM/feature/portable-data-setup")
Last completed step: Phase 6 (triage and fix design), provisional        Next step: Pause 5 with Holden: one status per row; then Phase 3 if the audit proceeds
```

Had the analyst chosen `audit`, Pause 3 would have shown the issue body (the WFS-FEM task template fields: objective, product, stakeholder group, lead, context, acceptance criteria), the branch name `N-review-ecospacebasemap-repo` and the draft pull request body with `Fixes #N`, and waited for a yes before writing anything to GitHub.

## 5. Phase 4: smoke and baseline, handed off

With no runtime, the skill wrote the smoke checks as a hand-off block in Doc C §3.8 and left every run-dependent cell reading "pending: run on the analyst's machine". Nothing in Doc B §9 was invented.

```
Command line (from the repository root):
  Rscript -e 'for (f in c("make_WFS_basemaps.R", list.files("R", "\\.[Rr]$", full.names = TRUE))) tryCatch({parse(f); cat("parsed", f, "\n")}, error = function(e) cat("PARSE ERROR", f, conditionMessage(e), "\n"))'
  Rscript -e 'print(setdiff(c("terra","sf","marmap","maps","colorRamps","mgcv","gstat","raster"), rownames(installed.packages())))'
  Rscript -e 'source("R/data_setup_functions.R"); invisible(fn.check_inputs("data", stop.on.missing = FALSE))'
  Rscript -e 'setwd(tempdir()); source("<absolute path to repo>/make_WFS_basemaps.R")'      # must stop at the anchor message
RStudio (open EcospaceBasemap.Rproj, then in the console): the same lines without the leading Rscript -e and quotes.
```

On the analyst's machine the equivalent with the skill's own scripts is `Rscript <skill>/scripts/static_sweep.R .` for the parse check and inventory, then `Rscript <skill>/scripts/run_logged.R make_WFS_basemaps.R` and `snapshot_md5.R` for the baseline. What comes back (the log tail, the environment table, the fingerprint CSV) is pasted into the session and parsed into Doc B §9.

## 6. Phase 5: the eight lenses

The findings register is where the skill earns its keep. Each lens gets a table; each row has a place, a problem, a kind, a severity and a proposed status; and each lens ends with a "checked, no finding" line so silence is never ambiguous. Two rows from the portability lens:

```
| P1 | make_WFS_basemaps.R:12 | rm(list=ls());graphics.off();gc() opens the driver, before the anchor check at :19-21, so sourcing the driver from another script loses that script's state ... | mechanical | low | open (fix: step 4 proposed) |
| P4 | make_WFS_basemaps.R:29-32; R/GFISHER functions.R:377-387 | No package check: a missing package fails at library('marmap') with R's own message rather than one install line ... The geodatabase read needs a GDAL build with the OpenFileGDB driver, which nothing states | mechanical | low | open (fix: step 4 proposed) |

Checked, no finding: root anchor present and strict (make_WFS_basemaps.R:19-21 ...); no setwd(), windows(), choose.dir(), file.choose() ... anywhere under *.R; machine paths only in commented examples ...
```

And two from the methods lens, which is where the `scientific` kind does its work:

```
| M1 | R/artificial_reef_functions.R:40-44,302-308,376,403; README :500-514 | FWC publishes Relief in feet (:40: the service alias is "Relief (ft)") while fn.make_AR_maps() computes sum(area_m2 * relief) / 1e6 / cell_area_km2 as though relief were metres ... Converting (x 0.3048) would scale all four AR layers by one constant and leave the k-means classes unchanged ... | scientific | high | author (proposed) |
| M3 | make_WFS_basemaps.R:177,179 with R/GFISHER functions.R:40-47,112-132,301-302,310-314,491 | anchor.zero = 'both' adds synthetic zero observations at every land cell and every cell deeper than max.depth to the IDW training set (the roxygen measured it: NL filled mean 0.0118 -> 0.0049 at 5 min), and max.depth.hab = 200 stops the fill at 200 m although the domain runs to 500 m ... Both are chosen to match the old maps (:314). Whether to keep either is the author's call | scientific | medium | author (proposed) |
```

The run found 40 rows across the eight lenses, with `file:line` on every one. The answer to the analyst's direct question ("which findings would you send to Dave") fell straight out of the Kind column: the eight M rows go to the author with the arithmetic untouched; two behavioural items (dropped NA-relief records, the fallback that loses settings) need his confirmation because outputs change; everything mechanical (paths, guards, dead code, documentation, the second-run failure, the live download with no cache) can be fixed with identical-output evidence.

Pause 5 is the long conversation: one status per row, in lens order. A typical exchange on this repository: "P1 to P4, fix. R1, fix, cache the bathymetry. B2, ask Dave first and size it from the data. M1 to M8, to Dave as decision issues. E5, won't fix, keep the CSV whole."

## 7. Phase 6: fix design and the decisions log

Doc C §4 lists the configuration keys the fixes introduce (`dir.bathy`, `seed.ar`, `stop.on.qc`), the setup checks, one line of code change per finding with its backward-compatibility note, the housekeeping moves, and the constraints. §7 is the decisions skeleton; in a live session each "pending" becomes a dated, owned line at Pause 5 or in the issue:

```
1. 6 Oct 2026 (Holden, by instruction): Review-only pass; documents written to the named outputs folder, not into the repository; no GitHub writes, no commits, no run. (scope)
3. pending (Holden with Dave): Track the deliverable grids (output/5min/**/*.asc, the two sum-1 CSVs and the port assignment CSVs, about 70 small files) so a rebuild shows in git diff and a fresh clone has a reference; or keep outputs out of the repository and name where the reference copy lives. (R4; mechanical; housekeeping commit either way)
5. pending (Dave, Holden): Fix the NA-relief drop in fn.fill_reef_relief(); outputs change for every structure that currently inherits NA relief. Needs the count from the data first. (B2; behavioural)
10. pending (Dave): M1, M3, M4, M5, M6, M7, M8 each need a [Decision] issue per the WFS-FEM profile; the arithmetic stays as it is until the outcome is filled in. (§8)
```

§8, "needs examination", gives the author what he needs to decide without re-deriving anything. For M1:

> FWC publishes `Relief` in feet; `fn.make_AR_maps()` multiplies footprint area by it as metres (`R/artificial_reef_functions.R:376,403`), and the roxygen and README describe a median of "8 m". ... Options: (a) convert at read time (`relief * 0.3048`), which scales the AR index by one constant and leaves the Low/Medium/High classes unchanged, then regenerate and document the index as metre-weighted; (b) keep the arithmetic and document the index as feet-weighted, with the inflation factor stated as the stored median; (c) switch to `weight.by.relief = FALSE` for a genuine covered fraction (README `:505` calls this "arguably the more defensible layer"). Not changed, so outputs stay comparable with the verified grids. Needs: Dave's choice; one run with the chosen option; the before/after table of AL/AM/AH means.

## 8. Phases 7 to 9: what happens on the analyst's machine

Nothing below happened in this run; it is what the `audit` mode does next, shown with the shape of evidence a finished audit carries (the GFISHER review in `docs/examples/full-audit-gfisher.md` is the real article).

1. **Proceed to `audit`.** `/code-audit` again, mode `audit`: the skill opens the issue and branch, renames `draft-review-ecospacebasemap-repo-log.md` to `issueN-review-ecospacebasemap-repo-log.md`, commits the three documents (`docs`), and opens the draft pull request.
2. **Smoke, then baseline.** Paste back the smoke output; run `run_logged.R` on the unmodified driver and `snapshot_md5.R snapshot` on the outputs; the skill writes Doc B §9 as-found and makes a `record` commit. A finished §9 reads like this (from GFISHER): "**Result: all stages ran to completion. Exit code 0. Wall time 15 min 39 s.**", followed by the comparison table whose Cause column explains every changed file.
3. **Implement, one step per commit.** The mechanical fixes first (P1-P4, R1, B1, the D rows), each with `identical()` or fingerprint evidence in the commit body; then the behavioural ones the author approved (B2, M2) under their decision numbers; outputs regenerated as their own `outputs` commit after Pause 8; the `hoard/` moves as a `housekeeping` commit listing every file.
4. **Verify the three targets.** A fresh clone without data stops with the MISSING table; a fresh clone with the data placed and a three-line `config.local.R` completes under `Rscript`; the author's interactive run on the same commit is byte-identical; the convention greps are empty. Doc C §9 is ticked except the author's sign-off.
5. **Finish.** README sync from Docs A and B, the pull request description from the template (with "running it back on the original machine"), the pre-ready check (no `open` rows, no placeholders), the closing summary, and the decision issues for M1 to M8 opened with the WFS-FEM decision template.

## 9. What the analyst says at each pause

| Pause | Where | A typical reply on this repository |
|---|---|---|
| 1 | After the interview | "Yes. Whole repo, no arithmetic changes, reference outputs are the legacy grids." |
| 2 | After orientation | "That's the pipeline. Section 5's digitising step is Python and out of scope." |
| 3 | Before GitHub writes | "Issue title fine; branch fine; open the draft." |
| 4 | Before the baseline | "Run it; expect about 15 minutes; I'll paste the log." |
| 5 | After the registers | "P1-P4 fix. R1 fix. B2 ask Dave. M1-M8 to Dave. E5 won't fix." |
| 6 | After fix design | "Plan approved. Run through step 4, then show me." |
| 7-9 | During implementation | "Go." / "Show me the before/after table first." |
| 10 | Before ready | "Ready. Request Dave." |

## 10. Time and cost

This review-only run took 68 tool calls and about 35 minutes of wall time in the container, and produced 1,086 lines across the three documents. The baseline run on the analyst's machine takes whatever the pipeline takes (the README claims seconds to a few minutes per section for this repository; the GFISHER baseline took 15 minutes 39 seconds). The triage conversation at Pause 5 is usually the longest human step.

## 11. Where the documents live afterwards

In review-only mode the documents land wherever the analyst named (here, a scratch folder). Once the audit proceeds they are committed to `docs/review/` in the repository, Doc C renamed to its issue number, and they travel with the pull request. The next audit of the same repository starts by reading them.
