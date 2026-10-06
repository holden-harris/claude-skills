# Example: a full audit (GFISHER, issue #2, pull request #4, October 2026)

Source: `docs/issue2-review-gfisher-repo-plan.md` in https://github.com/WFS-FEM/GFISHER (451 lines). It predates this skill and is the single document that the skill's Document C generalises; its evidence sections became Doc B §9. Excerpts below are verbatim except that names of people are replaced by their roles, `[analyst]` (the person running the audit) and `[author]` (the original author of the code); commentary follows each.

## The opening pins everything

```
# GFISHER issue #2: Review GFISHER repo

Date opened: 1 Oct 2026. Branch: `2-review-gfisher-repo`. Pull request: #4 (draft).
Authors: [analyst], with Claude Code. Original code author: [author].

Sections 1 to 4 describe what was found. Sections 5 to 8 are the work plan. Section 9 logs
decisions as they are made. This file is updated as the work proceeds and travels with the PR.
```

What to notice: branch, pull request, both authors and the document's own rules are in the first seven lines, and the findings section adds "Line numbers refer to the merged branch at commit `3e4dea1`". The skill's Doc C §0 status block keeps this and adds the last completed step, so a fresh session knows where to resume.

## The three standing goals

```
1. [analyst] can run it (Windows 11, R 4.5.1, RStudio).
2. [author] can still run it with their existing paths and habits.
3. Any new GitHub user can run it, accepting that the geodatabase and survey CSVs cannot
   live on GitHub.
```

Every findings category in the document says which goal it blocks ("Portability (blocks goals 1 and 3)"). The skill names the same three targets in Doc C §1 and verifies each in Phase 8.

## Findings as tables with IDs and `file:line`

```
| P1 | `process GFISHER data.R:26` | `dir.ecospace.maps` hardcoded to [author]'s OneDrive. Required by stage 1 (seagrass layer). |
| P3 | `process GFISHER data.R:1,105` | `rm(list=ls()); rm(.SavedPlots); windows(record=T)`: wipes the user's workspace, warns when `.SavedPlots` is absent, fails off Windows or under `Rscript`. |
| R1 | `R/video_dataset.R:161-169` | `rtruncnorm` and `sample.int` draw random lengths with no `set.seed`, so stage 2 and everything downstream (MaxN maps, affinities) differ on every run. |
| B4 | `R/maxn_maps.R` | `save.format` argument is accepted but ignored (always writes ASCII). Header says `fun='sum'`; the driver passes `mean`. |
```

What to notice: one problem per row, the exact place, and enough of the mechanism to be checked by someone else. What the document lacked, and the skill adds: a Kind column (P1 and P3 are mechanical; R1 is behavioural, it changes outputs) and a Status column. Finding B2 in this audit was never resolved and never cited again; a Status column would have shown it.

## The baseline run, recorded before any change

```
**Result: all stages ran to completion. Exit code 0. Wall time 15 min 39 s.**

| Output group | Identical | Changed | Cause |
|---|---|---|---|
| `output/basemaps/15min/` (10 files) | 10 | 0 | not regenerated at `res = 5` |
| `output/basemaps/5min/` (10 files) | 0 | 10 | seagrass input only, see below |
| `output/maps/.../maxn/mice/` (19 rasters) | 8 | 11 | unseeded length draws (R1): the 8 unchanged are the single-stanza groups plus red-grouper-0; the 11 changed are the gag and red grouper age stanzas |
```

What to notice: the environment line above it (OS, R version, package versions), the exact commit and the two local edits made to run it, and a Cause for every changed group. The paragraph that follows ("the seagrass raster is the only source of difference ... in the other 3,793 water cells all nine layers are bit-identical") is what root-causing a comparison looks like. The baseline also surfaced a new finding (R5, a grid template with a rounded cell size) that was appended to the register with its origin.

## Same seed, different seed

```
| Test | Result |
|---|---|
| Same seed twice | Stage 2 tables `identical()`; all 19 rasters byte-identical |
| Grand total MaxN, seed 1 vs seed 2 | 1,043,543 in both |
| 7 single-stanza maps | identical across seeds |
```

"So the seed changes exactly one thing ... Nothing is gained or lost." And then the honest reading: "`set.seed()` makes the stanza maps reproducible but does not make them less noisy." The ten-seed experiment that followed (section 4.1c) ends with three options and the sentence "which is appropriate is a modelling judgement for [author]", tracked in issue #5. That is the skill's `scientific` kind in action: measured, documented, handed over, arithmetic unchanged.

## Acceptance criteria as commands

```
- [x] `git grep -nE "<author login>|OneDrive"` over `*.R` matches only comments in
      `config.local.example.R`. `git grep -n "windows("` matches nothing.
- [x] `git ls-files --cached --ignored --exclude-standard` is empty (housekeeping commit).
- [ ] [author] runs the branch with their `config.local.R` and confirms the outputs.
```

What to notice: each criterion can be re-run, and the last one is the author's and stays open. The skill widens the path grep (`[A-Za-z]:/|/Users/|/home/|OneDrive|AppData`), because this one missed two machine paths in the experiment script committed with the document.

## Decisions, dated and owned

```
2. **1 Oct 2026 ([analyst]):** Swap `xlsx` for `readxl`.
6. **2 Oct 2026 ([analyst]):** Track the four raw dbSEABED grids in `data/dbseabed/` (copied
   byte-identical from EcospaceBasemap, provenance in `SOURCE.md`) after the CSDMS server
   proved unreachable (R6). The duplication with EcospaceBasemap is tidied under issue #3.
```

## Commits split by type, with record commits

From the branch: "Record the baseline run: all stages run; seagrass and seeding explain the diffs (issue #2)" (documents only, 1 Oct) lands before "Make the driver's paths portable and check inputs up front (issue #2)" (code, 2 Oct), whose body ends with an evidence paragraph: "the nine basemap layers and QC table are byte-identical to the baseline run". Later: "Record the stochasticity check on the stanza maps", "Remove the dead estimate_habitat_affinities.R", "Stop tracking legacy data and a stale output folder; align .gitignore with what is tracked", and finally "Regenerate outputs: shipped seagrass, seeded stanza draw, exact grid template" as its own outputs-only commit.

## What this audit did not have, and the skill now requires

- A status per finding and a closing table of outcomes (B2 was left open without a word).
- Late findings always entering the register (R6 lived only in prose).
- A placeholder check before "ready for review" (line 95 still read "to be added in section 4.1").
- A plan-versus-code check (section 5.3 says "remove workspace wipe"; the driver still begins `rm(list=ls())`).
- Experiment scripts obeying the repository's own path rule (`docs/issue5_seed_experiment.R` lines 4 and 6 carry machine paths).
- A separate, plain-language Workflow Review (B) and Science Review (A); here the science lived in the README and CLAUDE.md.
