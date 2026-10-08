# Example: a pull request description (EcospaceBasemap, pull request #1, September 2026)

Source: https://github.com/WFS-FEM/EcospaceBasemap/pull/1, "Make EcospaceBasmap pipeline generalizable (runnable by [analyst] or anyone)". This is the model for `assets/pr-description.md`. The body is reproduced in full (lightly reflowed, with names of people replaced by their roles `[analyst]` and `[author]`); commentary follows.

---

Hey [author]. I have it set up that I can run this repo and everything looks good.

Next, I wanted to use this as a test-case of making a generalizable work flow so anyone can do it, including updating your original code. This is the first time I've tried making a pull request.

Claude and I have tried to be diligent about tracking changes. These should be in different commits. Claude also identified a potential units issue with relief being treated as both feet and meters.

## Changes made

**Paths** (`make_WFS_basemaps.R`). Repo-relative defaults: `data/` for inputs, `output/<res>min/` for grids, geodatabase discovered by extension. Any of the three can be redirected from `config.local.R`, which is gitignored, so machine-specific paths never reach the repo. Also a working-directory guard (both the `R/` sourcing and `dir.data` derive from `getwd()`, and a wrong one failed confusingly), `dir.create(recursive = TRUE)` which was warning and creating nothing when a parent was missing, and the RGui-only calls on line 1 guarded so the script runs under `Rscript`.

**Input manifest** (`R/data_setup_functions.R`, new). One place that records every input: source, terms, target path, expected files and columns. `fn.check_inputs()` reports what is present and stops early if a required input is missing; `fn.pull_all()` fetches everything downloadable, skipping what is already on disk. The driver, its error messages and the README all read from this one manifest, so they cannot drift apart.

**Two new downloads.** `fn.pull_seagrass_fwc()` and `fn.pull_reeflocations()` fetch the FWC statewide seagrass layer and the artificial reef deployment table from FWC's open data portal. Both were previously "supply by hand", which made sections 2.1 and 2.4 unreproducible. The reef table is normalised to the contract `fn.make_AR_maps()` already reads against rather than changing that reader.

**Graceful degradation.** Missing optional inputs no longer abort a run. Without the FWC seagrass layer, section 2.1 uses GulfwideSAV alone. Without `reeflocations.csv`, section 2.4 falls back to `weight.by.relief = FALSE` and writes the three relief classes as zero grids, since relief is the only thing the k-means split classifies on.

**Docs.** "Input data" rewritten as "Getting the data": per-dataset acquisition instructions, terms, expected `data/` tree. New "For collaborators" section on `config.local.R` and the branch/PR workflow.

## Needs examination

**1. FWC publishes reef `Relief` in feet, not metres.** The service field alias is literally "Relief (ft)", while `fn.make_AR_maps()` multiplies footprint area by it as though it were metres. That is inherited from the legacy script, and I deliberately left the arithmetic alone so output stays comparable with the verified legacy grids, but it compounds the existing "this is an index, not a proportion" caveat. The degraded (unweighted) run puts the inflation at roughly 25x, not the ~10x the README estimates.

## Also flagged for review in this pull request

**2. The FWC endpoints serve the current compilation, not the vintage the legacy scripts used.** FWC revises both layers periodically. `fn.pull_all()` skips inputs already on disk, so anyone holding an existing `Seagrass_Statewide/` keeps it; only a fresh clone gets the new vintage. Flagged in the README, but you may want a stronger position on pinning.

**3. Two small fixes the first cold run exposed**, both in this PR:
- Every download helper now raises R's 60-second `download.file` timeout. The seagrass archives are 100 to 230 MB, so the default would abort them on an ordinary connection; the downloads had simply never been run on a machine that didn't already have the data.
- The "cells exceed 1" check in `fn.combine_seagrass_rasters()` used a `1e-9` tolerance, tighter than float32 epsilon. `cover = TRUE` accumulates per-polygon fractions in single precision, so a fully covered cell lands ~2.4e-8 over 1; 137 such cells in GulfwideSAV alone at 5 min. I measured this before changing anything, since a seagrass layer genuinely exceeding 1 would have been a real problem. Tolerance is now `1e-6`; real double-counting is percent-scale.

## Running it back on the original machine

After merging, create `config.local.R` in the repo root, one file, gitignored, and the only thing you need:

```r
# restores the output location the driver used to hardcode
dir.basemaps <- file.path("C:/Users/<author>/OneDrive - University of Florida",
                          "WFS Fisheries Ecosystem Modeling/WFS EwE/Ecospace/basemaps",
                          paste0(res, 'min'))
```

That is all. `dir.data` keeps its default, because your geodatabase and the redacted reef CSV are already in `data/` where the driver looks; `file.gdb` stays `NULL`, because the `.gdb` is found by extension. `fn.pull_all()` skips every input you already have, so your existing data, and therefore your existing grids, are unchanged. The only new fetch is `reeflocations.csv`.

The first run should reproduce the previous 5 min grids. That's the check worth making before trusting anything else here.

---

## What to notice

- **It is written to a person.** The author is addressed by name, told what to expect, and given the one file they need. The skill's Phase 9 keeps this register.
- **Changes are grouped by theme, each with the why.** Not a commit list; the commits carry the detail.
- **"Needs examination" is separate from the fixes**, and the arithmetic was left alone on purpose so outputs stay comparable. In the skill this is a `scientific` finding with status `author` (findings log §8).
- **Measurements before changes.** "I measured this before changing anything" (137 cells, 2.4e-8 over 1) is the evidence habit the skill asks for in every commit body.
- **The closing check is concrete.** "The first run should reproduce the previous 5 min grids" names the one thing the author should verify first. The template ends with the same sentence pattern.
- **Housekeeping and provenance appear even here**: the vintage-drift flag and the skipped-download behaviour are explained in terms of what the reader holds on disk.
