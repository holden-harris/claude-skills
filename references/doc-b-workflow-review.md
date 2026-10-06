# Template B: Workflow Review (`docs/review/workflow-review.md`)

## How to use this template

Document B is for an analyst who has never seen the code and needs to run it, trust it and maintain it. It is the long document of the three. It is drafted in Phase 2 (§1-2), filled during Phases 4 and 5 (§3-8 and §9 as-found), and finalised in Phase 8 (§9 as-left) with §0 written last.

Plain-language rules, because the reader is not the person who wrote the code:

- Define every technical term the first time it appears, in the sentence itself or in a parenthesis, and collect them in the glossary (§10). Prefer the plain phrase: "a grid of cells" before "raster"; "the map coordinate system" before "CRS"; "a fingerprint of the file's contents" before "MD5"; "the starting number for the random draws" before "seed".
- Start each subsection with one sentence on why it matters to someone running the pipeline.
- Numbers go in tables with their cause or source next to them. Prose carries the reading.
- Say what happens when something is missing or fails. Silence about failure modes is the most expensive gap in this document.
- Length is whatever the content needs; a short pipeline gets a short B.

Below, each section has a heading to copy, guidance in a blockquote (delete it when writing), and examples drawn from real audits. The examples are illustrations of shape from other repositories; nothing in them is a fact about the repository being audited.

---

# Workflow Review: <repository name>

## 0. How to read this document

> Who it is for; the plain-language promise; the document map (A for the science, this document for running and maintaining, C for the audit record and decisions); the commit the line numbers refer to; last updated. Write this section last.

## 1. The pipeline in one page

> The input-to-output story in a paragraph, then the stage table. Add a diagram only when the flow branches or loops.

| Stage | What goes in | What comes out | How long | Where in the code (file and main function) |
|---|---|---|---|---|
| 1 Habitat basemaps | geodatabase, dbSEABED grids, seagrass raster | nine sum-to-1 layers per cell | ~12 min (geodatabase read dominates) | `R/habitat_basemaps.R` |
| 2 Video dataset | three survey CSVs, species list | station x group MaxN table | ~1 min | `R/video_dataset.R` |

(Example rows from GFISHER; the run times come from Doc B §9, not from guesses.)

## 2. Setting up and running

> 2.1 Software: OS and language version the pipeline was tested on; packages and versions (from the environment capture in §9); system libraries that must exist (for spatial work: GDAL, GEOS, PROJ); what the package check prints when something is missing.
> 2.2 Configuration: the table of keys (key | default | purpose | when to change it); the local override file, that it is gitignored, and that the code reads it after its defaults and before any input. The original author's layout as the worked example of an override.
> 2.3 Entry point and run modes: the one file to run; interactive (open the project file, source) versus command line (`Rscript`); what differs between them (plot windows, working directory).
> 2.4 The three run targets: the analyst's machine, the original author's layout, a fresh clone with the documented data placed; what each needs and which section of §9 verifies it.
> 2.5 What a first run prints: the input-check table and how to read OK, MISSING and DRIFT.

Example configuration rows (GFISHER):

| Key | Default | Purpose |
|---|---|---|
| `dir.data` | `data/April2026` | Folder with the geodatabase and the three survey CSVs (cannot ship) |
| `seed` | `1` | Seed for the stage 2 length draws; `NULL` restores the unseeded behaviour |

Example of the input-check output (EcospaceBasemap):

```
  input                 sect  need      source  holding          status
  seagrass_fwc          2.1   optional  auto    86,173 features  OK
  artificial_reefs_fwc  2.4   optional  auto    4,611 lines      DRIFT
```

"DRIFT is a flag, not an error: the run continues, but your grids will not match a run built from the reference data."

## 3. Data inputs

> One subsection per input, in the order the pipeline reads them. For each: what it is (one sentence a non-specialist can follow); who provides it and under what terms; how to obtain it (ships with the repository / downloads itself / by request); size; where it sits on disk and which configuration key points at it; which stages read it; what happens without it (stops, degrades, silently zero); vintage and drift (how to know which version you hold; what the reference counts are); provenance (what the code records about your copy). Then the expected data tree, annotated, and the summary table.

Summary table header (from GFISHER §4.2):

| Input | Size | Used by | Source | How a user gets it |
|---|---|---|---|---|

Example subsection (EcospaceBasemap, "The two that cannot ship"): "The GFISHER geodatabase (274 MB) holds the side-scan habitat polygons. It is FWRI data provided on request and cannot be redistributed on GitHub; place it in `data/` or point `file.gdb` at where it already sits. Section 2.3 reads two layers from it. Without it the habitat stage cannot run and the input check stops before any slow work."

Live web inputs count as inputs: a download made on every run (for example, bathymetry fetched from a server inside the code) needs its own subsection, with what is pinned and what is not.

## 4. Pipeline and data transformations

> One subsection per stage: inputs; the steps in order, in plain words; intermediate files and where they go; where resolution, map coordinate system or units change; the invariants that must hold at the end (for example "the habitat layers sum to one in every water cell") and where the code checks them; QC outputs written; failure behaviour (what stops the run, what only warns, what continues silently).

Example invariant (GFISHER `CLAUDE.md`): "The basemap layers sum to exactly 1 per water cell (six reef classes + rock + unconsolidated + seagrass). Anything added must enter the normalisation or the invariant breaks silently; the QC block prints the minimum and maximum row sums for this reason."

Example failure behaviour worth recording (EcospaceBasemap): "The sum-to-one QC and the seagrass 'cells exceed 1' check are warnings, not errors, and nothing summarises them at the end of a run."

## 5. Statistical models and estimators

> One subsection per model, test or estimator. For each: the question it answers, in one plain sentence; its inputs; the assumptions it makes and whether the data meet them; how it is fit (and with what settings); the diagnostics the code prints or saves; what happens on failure or fallback, and whether the settings survive the fallback; where the parameters are set (driver, function default, config); how the result feeds the next stage. Every model subsection states its assumptions explicitly, even when the code does not; write "assumptions not stated in the code" rather than leaving the item out.

Example (EcospaceBasemap §2.3): "Where the survey did not map a cell, the natural reef fractions are filled by inverse-distance weighting (nearby mapped cells count more, falling off with distance to the fourth power, eight neighbours). A smoothing model and ordinary kriging exist in the same function. When kriging fails the code falls back to the inverse-distance fill, but the fallback call does not pass the anchoring, strata or clamping settings, so a failed fit silently runs with different settings (finding M3)."

Example (GFISHER stage 4a): "Habitat affinity is a selection ratio: how often a group was seen over a habitat relative to how available that habitat is. Uncertainty comes from 1,000 bootstrap draws, seeded. Sparse groups (fewer than about 50 occupied cells) give ratios that depend on the random stanza assignment (Doc B §6)."

## 6. Randomness and reproducibility

> Every place the code draws random numbers (list them with file and line); where the seed is set and its side effects (a seed set inside a function also resets the session's random state for everything after it; a seed set at the top of a file runs whenever the file is sourced); what changes between runs with and without a seed; the same-seed and cross-seed evidence (table); sensitivity results if an experiment was run; what stays non-deterministic even with a seed (live downloads, package versions, parallel reductions).

Example evidence table (GFISHER §4.1b):

| Test | Result |
|---|---|
| Same seed twice | stage 2 tables identical; all 19 rasters byte-identical |
| Seed 1 vs seed 2, per-species total MaxN | identical for every species |
| Seed 1 vs seed 2, stanza maps | 13 to 229 cells changed per map; a fixed seed makes them reproducible, not less noisy |

## 7. Outputs

> The final products: file, format, units, grid and no-data conventions; which are tracked deliverables (the versioned product someone downstream consumes) and which are intermediates kept out of version control; who consumes each and how; how to sanity-check them (a plot to look at, a sum that must hold, a count to compare). Then the output tree.

Example (RedTideMaps `.gitignore`): "Only the deliverables are tracked (`out/<res>min/ecospace_ascii/`, `plots/`); the heavy intermediates (`sdm/`, `clipped/`, `combined/`, run logs) are ignored." Example (GFISHER): "Stage 1 overwrites `output/basemaps/` in place so a rebuild shows up in `git diff`; that is deliberate, because the basemaps are the versioned deliverable."

## 8. Run times and efficiency

> 8.1 Timing table from the baseline (stage | wall time | what dominates | cache or skip candidate), with the conditions (machine, cold or warm cache, other jobs running).
> 8.2 Existing caches and skip toggles, and how a rerun behaves (what is skipped, what is overwritten, what fails on a second run).
> 8.3 Proposed caches and toggles, each with the time it would save and what it would store.
> 8.4 Code inventory: never-called functions, never-sourced files, duplicate definitions, scratch folders, tracked files no code reads; what was moved to `hoard/` or `archive/` and in which commit.

Example rerun table (RedTideMaps README "Monthly rerun"):

| Toggle | Effect on a rerun |
|---|---|
| `incremental_fit = TRUE` | refits only months with new data; 8 min 50 s instead of about 19 min |
| `fit_nb = FALSE` | skips the negative-binomial stack |

Example second-run failure (EcospaceBasemap): "`terra::writeRaster()` in the dbSEABED step has no `overwrite = TRUE`, so running into an existing `output/` folder errors (finding B2)."

## 9. Verification record

> 9.1 As-found baseline: environment (OS, language version, key package versions); the commit run and any local edits made to run it; bold result line (exit code, wall time); per-stage table (stage | ran | log evidence); warnings tied to finding IDs; the comparison with the committed outputs (output group | identical | changed | cause), with every change explained; where the copy of the baseline outputs and the fingerprint CSVs live (outside the repository).
> 9.2 Same-seed, cross-seed and sensitivity results, if not already in §6.
> 9.3 As-left verification: the three targets (fresh clone without data fails fast with a readable table; fresh clone with data and a minimal config completes from the command line; independent interactive run on the same commit), the byte-identity statement, the regenerated-versus-committed table (output | change | cause) where every row cites a finding ID or decision number, and the convention checks (machine-path and platform-call greps empty; tracked-but-ignored list empty).
> Protocols and command lines are in the skill's `references/verification.md`. In a session that cannot run the code, this section reads "pending: run on the analyst's machine" until the results are pasted in.

Example result line and table (GFISHER §4.1): "**Result: all stages ran to completion. Exit code 0. Wall time 15 min 39 s.**"

| Output group | Identical | Changed | Cause |
|---|---|---|---|
| `output/basemaps/5min/` (10 files) | 0 | 10 | seagrass input differs in 45 cells; all other cells bit-identical |
| `output/maps/.../maxn/mice/` (19 rasters) | 8 | 11 | unseeded length draws (R1): the 11 changed are the age stanzas |

## 10. Appendices

> 10.1 Configuration keys (full table). 10.2 Function inventory (file | function | purpose | called by), from the static sweep. 10.3 Package list with versions (from the environment capture). 10.4 Glossary. 10.5 Command cheat-sheet (run, rerun, check inputs, snapshot outputs, compare).
