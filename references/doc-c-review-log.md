# Template C: Issues Flagged, Recommended Changes and Decisions (`docs/review/issueN-<slug>-log.md`)

## How to use this template

Document C is the working record of one audit: what was found, what was decided, what changed, and what is still open. It is created in Phase 3, updated before every commit, and is the state the skill resumes from after an interruption. One C per issue; a later audit opens a new one and carries over what the previous one left open.

Guardrails built into the layout, each because a past audit needed it:

- Every finding has a **Status** and the closing summary (§11) lists an outcome for every ID, so nothing is quietly dropped.
- Findings discovered later (by the baseline run, by a fresh-clone test) are appended to their register with their origin, never left in prose only.
- The **change log** (§6) has one row per commit with the IDs it closed, so the trail from finding to fix is in one place and `git log --grep=<ID>` confirms it.
- **Decisions** (§7) are numbered, dated and owned; a behavioural or scientific change may not enter the plan (§5) without one.
- Placeholders ("to be added") are allowed while work proceeds and are a blocker for "ready for review" (pre-ready check, §11).
- Experiment scripts committed alongside this document take their paths from the configuration or from arguments and reproduce the tables they are cited for.

Below, each section has a heading to copy, guidance in a blockquote (delete it when writing), and examples drawn from a real audit. The examples are illustrations of shape from other repositories; nothing in them is a fact about the repository being audited, and names of people in them are replaced by roles in square brackets. The appendix holds the short form used in `fix` mode and the carry-over block used in a second audit.

---

# <Repository> issue #N: <title>

## 0. Status

> Keep this block current; it is what the skill reads first.

```
Issue: #N (<link>)        Branch: N-<slug>        Pull request: #M (draft)
Mode: audit | fix | review-only | resume | second audit        Org profile: <name>
Reviewer: <name>, with Claude Code        Original author: <name>
Line numbers refer to commit: <sha>
Last completed step: <§5 step k>        Next step: <§5 step k+1>        Last updated: <date>
```

## 1. Scope and targets

> The three run targets, named: who, on what machine, with what layout. What is in scope; what is explicitly out and which issue tracks it. Which documents this audit produces or revises (A, B, this C).

Example (GFISHER): "1. [analyst] can run it (Windows 11, R 4.5.1, RStudio). 2. [author] can still run it with their existing paths and habits. 3. Any new GitHub user can run it, accepting that the geodatabase and survey CSVs cannot live on GitHub. Whether the basemap stage belongs in this repository is issue #3 and out of scope here."

## 2. Findings register

> One table per lens, in this order: P portability, R reproducibility, B bugs and fragility, D documentation, M methods and statistics, S stochasticity, T run time, E efficiency and artifacts. IDs are the lens letter plus a number and are never reused. Columns:
>
> - **Where**: `file:line` against the commit in §0; a quoted snippet in §3 when the line alone is not self-explanatory. For a finding about a folder, a data file or a README section, give the path plus the line of the code or text that establishes the problem, so every row still carries a line.
> - **Kind**: `mechanical` (fixing it does not change outputs), `behavioural` (outputs change: seeding, grid template, input swap), `scientific` (what the method means changes: units, thresholds, pooling, parameter choices). Behavioural needs a decision number; scientific goes to the author (§8).
> - **Severity**: `high` (blocks a run target or materially changes outputs), `medium` (wrong or fragile with a workaround), `low` (tidy-up, wording).
> - **Status**: `open`, `fix: step k`, `author` (handed over in §8), `issue #M` (sub-issue opened), `wontfix (decision n)`.
>
> "None found; checked X, Y, Z" is a valid table body. Carry-overs from a previous audit keep a note of their origin in the Problem cell.

### 2.1 Portability (P)

| ID | Where | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| P1 | `process GFISHER data.R:26` | `dir.ecospace.maps` hardcoded to the author's cloud-drive folder; required by stage 1 | mechanical | high | fix: step 3 |
| P3 | `process GFISHER data.R:1,105` | `rm(list=ls()); rm(.SavedPlots); windows(record=T)`: wipes the user's workspace, fails off Windows and under Rscript | mechanical | medium | fix: step 3 |

### 2.2 Reproducibility (R)

| ID | Where | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| R1 | `R/video_dataset.R:161-169` | `rtruncnorm` and `sample.int` draw random lengths with no `set.seed`, so stage 2 and everything downstream differ on every run | behavioural | high | fix: step 4 (decision 2) |
| R5 | `output/.../GFISHER_survey_effort_5min_66x78.asc` | Committed effort raster built on a template with `CELLSIZE 0.0833333333329999`; seven stations on a row boundary fall differently. Found by the baseline run (§3) | behavioural | medium | fix: step 8 (decision 6) |

### 2.3 Bugs and fragility (B)

| ID | Where | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| B4 | `R/maxn_maps.R` | `save.format` argument accepted but ignored; always writes ASCII | mechanical | low | fix: step 6 |

### 2.4 Documentation (D)
### 2.5 Methods and statistics (M)
### 2.6 Stochasticity (S)
### 2.7 Run time (T)
### 2.8 Efficiency and artifacts (E)

> Same table shape for each.

## 3. Evidence notes

> Only for findings that needed a measurement or a quoted snippet to be believed: the command run, the number observed, the date. Everything about the baseline and verification runs lives in Doc B §9; link to it rather than repeating it.

Example (GFISHER R5): "Found by the baseline run: 14 cells differ by one station each, in seven pairs of vertically adjacent cells; the committed header reads `CELLSIZE 0.0833333333329999` while the depth grid carries the exact 1/12 degree. Cause settled 2 Oct 2026: an older template, not a package-version effect."

## 4. Recommended changes (fix design)

> 4.1 Configuration: table of keys (key | default | purpose) the fix introduces or changes, and how the original author's layout maps onto them (their real paths become commented examples).
> 4.2 Setup checks: package check, root anchor, input manifest and check, download fallbacks.
> 4.3 Code changes: one line per finding ID, with the backward-compatibility note (new arguments get defaults that reproduce the old behaviour).
> 4.4 Housekeeping: what moves to `hoard/` or `archive/`, what leaves the index, the `.gitignore` rewrite.
> 4.5 Alternatives considered and why not.
> 4.6 Constraints: no new dependencies beyond <X>; existing function signatures keep working; functions not to touch; OS and version; evidence commands to use.

## 5. Implementation plan

> Ordered checkboxes. Each step carries its commit type and the IDs it closes. Mark the agreed pause points. Tick as you go; the skill resumes at the first unticked box.

- [x] 1. Commit this document and the A and B drafts. (docs)
- [x] 2. Baseline run and snapshot; record in Doc B §9. (record)
- [ ] 3. Portability: root anchor, setup file, config example, driver edits, `.gitignore`. (code; P1, P2, P3, P4, P8)
- [ ] 4. Seed the stage 2 draws; swap the Java-dependent reader. (code; R1, P5; decision 2)
- [ ] 8. Regenerate outputs with the seeded pipeline. (outputs; pause before)
- [ ] 10. Fresh-clone verification; tick §9; mark the pull request ready. (record)

## 6. Change log

> One row per commit, added before or with the commit.

| Commit | Kind | IDs closed | Evidence | Documents updated |
|---|---|---|---|---|
| `8bafbaa` | code | P1, P2, P3, P4, P8 | smoke-tested three ways; stages 1-4a byte-identical to baseline | Doc B §2, Doc C §5 |
| `a565205` | record | (S check) | same seed identical; cross-seed invariants hold | Doc B §6 |

## 7. Decisions log

> Numbered, dated, owned. One line each; the discussion lives in the issue, so link it. List the findings a decision affects.

1. **1 Oct 2026 ([analyst]):** Review the rework branch rather than `main` alone. (scope)
2. **1 Oct 2026 ([analyst]):** Seed the stage 2 draws with `seed = 1`, overridable in the local config. (R1; behavioural)
6. **2 Oct 2026 ([analyst]):** Ship the four public substrate grids in `data/` with a provenance note after the source server proved unreachable. (R6)

## 8. Needs examination (for the original author)

> Scientific items left unchanged. For each: the finding ID, the question, the evidence, the options, what was deliberately not changed and why, the sub-issue link.

Example: "M1 Reef relief is published in feet but the weighting treats it as metres (`R/artificial_reef_functions.R:302-308`). The index is roughly 25x the covered fraction rather than the 10x the README states. Left unchanged so outputs stay comparable with the verified legacy grids. Options: convert at read time and document the index as metres; or document the index as feet-weighted. Decision for the author; sub-issue #7."

## 9. Acceptance criteria

> Checkboxes, each citing the section that holds the evidence. The last one is the author's sign-off and stays open until they give it.

- [ ] A fresh clone with only the local config added completes from the command line (Doc B §9.3).
- [ ] Run from the wrong folder stops with the anchor message; a missing input stops before any slow work with a table naming the file and where to get it (Doc B §9.3).
- [ ] `git grep -nE "[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R'` matches only commented examples; `git grep -n "windows(" -- '*.R'` matches nothing.
- [ ] Outputs regenerate identically given the same inputs, or every difference has a cause (Doc B §9.3 table).
- [ ] Same seed gives identical outputs across two independent runs (Doc B §6).
- [ ] `git ls-files --cached --ignored --exclude-standard` is empty.
- [ ] A, B and the README describe the stages, inputs, outputs and tested environment.
- [ ] The original author runs the branch with their local config and confirms the outputs.

## 10. GitHub record

> Issue, branch, pull request and merge policy; the pull request description (from the skill's `assets/pr-description.md`); the "running it back on the original machine" block with the author's exact local config.

Example block (EcospaceBasemap): "After merging, create `config.local.R` in the repo root; it is gitignored and the only thing you need: `dir.basemaps <- file.path('<your former output folder>', paste0(res, 'min'))`. The first run should reproduce the previous 5 min grids. That is the check worth making before trusting anything else here."

## 11. Closing summary

> Written at Phase 9 after the pre-ready check (no `open` rows, no placeholders, every unticked §5 step carried to a sub-issue, every changed output explained in Doc B §9).

| ID | Outcome |
|---|---|
| P1 | fixed in `8bafbaa` |
| R1 | fixed in `0299a4d` (decision 2) |
| M1 | author; sub-issue #7 |
| B2 | wontfix (decision 8): legacy module, superseded |

Carried to the next audit: <list>. README and `CLAUDE.md` sections synced from A and B: <list>.

---

## Appendix 1: short form for `fix` mode

> One issue, one known problem. Keep §0 and use these sections instead of §1-11; add a kickoff prompt so the work can be handed to a fresh session.

1. Summary (what is wrong, where it shows, the root cause in one paragraph).
2. Where the affected cases come from (which inputs, months, cells).
3. Root cause, with `file:line` and the failure paths labelled A, B, C.
4. Evidence (table of affected and control cases; "every flagged case reproduces; no control case does").
5. Downstream impact.
6. Fix design: recommended fix with code sketch; parameter choice and its sensitivity; diagnostics and QA; alternatives considered; decisions (finalised, dated, owned).
7. Implementation steps for the session (confirm branch; read these files; change; QA script; baseline before the full run; full run; housekeeping; commit and PR), each with its pause.
8. Acceptance criteria (unaffected outputs keep their fingerprints and only the expected subset changes; a determinism check passes; no new dependency; a fresh clone still runs).
9. GitHub workflow for this fix.
10. Kickoff prompt: a paragraph a fresh Claude Code session can be given to continue from this document, naming the pause points.
11. References.

(Modelled on `RedTideMaps/docs/issue3-hull-fix-plan.md`.)

## Appendix 2: carry-over block for a second audit

> Paste at the top of §2 when a previous audit exists.

```
Carried over from docs/review/issue<N-1>-<slug>-log.md (merged in PR #<M>):
- Unticked acceptance criteria: <list>
- Needs-examination items still open: <IDs and sub-issues>
- Open sub-issues: #<a>, #<b>
- README "Known caveats" entries: <numbers>
Closed findings from that audit were re-checked on <date>: <one line, e.g. "P1-P8 confirmed closed: setup file and config example present; machine-path grep clean">.
First run step for this audit: drift check of a fresh run against the committed deliverables, plus the input status table.
```
