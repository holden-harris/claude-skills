# First local run: RedTideMaps, review-only, 6 October 2026

The first execution of the skill outside the authoring sessions: `/code-audit` in the analyst's clone of WFS-FEM/RedTideMaps (Windows 11, R 4.5.1, Claude Code), mode `review-only`, on `main` at a875d64. The skill was at commit 46b8414, before the documents were renamed, so the documents say "Doc A/B/C". The analyst committed the three documents to RedTideMaps `main` as ba406be (`docs/review/science-review.md`, `workflow-review.md`, `draft-repo-audit-log.md`; 157, 447 and 319 lines). This note grades that run against test case 2 of `evals.json` and records what the run taught.

## The scripts ran on a real R

All four scripts executed for the first time, and the documents cite their outputs: the static sweep's inventory (16 files parsed, 0 failures, pattern hits by file, function counts in the workflow review §8.4 and the findings log §3), `run_logged.R`'s per-stage timestamps and the stopped run's log (workflow review §9.1), `snapshot_md5.R` fingerprints taken before the run (`md5_*_before.csv`), and the `session_capture.R` package table (workflow review §10.3). No script error is recorded. Still to confirm with the analyst: whether any script printed a warning.

## Assertions of test case 2

| # | Assertion (short) | Result | Where |
|---|---|---|---|
| 1 | Workflow review plus a findings log named `draft-<slug>-log.md` in review-only mode | pass | `draft-repo-audit-log.md` |
| 2 | Stage table names the hull builder, the ASCII writer and the monthly fit function | partial | `fn.fit_monthly_sdmTMB()` and `make_redtide_ascii()` named; stage 5 lists three files and no function (`fn.buffered_hulls` appears in §4.5 and §10.2 instead) |
| 3 | Inputs split: tracked, pulled at run time into gitignored folders, optional network | pass | §3.1 to §3.4 |
| 4 | Outputs split: tracked deliverables against gitignored intermediates, citing `.gitignore` | partial | the split is stated in §7; `.gitignore` is not cited by line |
| 5 | File-scope `set.seed(6)` flagged; hull clustering deterministic since issue #3 | pass | §6, with the measured same-seed and no-seed fits on top |
| 6 | `incremental_fit` and README rerun timings as the existing cache; `rt_log` as the timing pattern | pass | §8.2; timings read from the `rt_log` lines of the run log (§8.1) |
| 7 | `scripts/old scripts/` and the placeholder `scripts/README.md` flagged | pass | E3, D4 |
| 8 | `download.file` without a raised timeout at `scripts/get_HAB_data.R:211` | pass | B9 (B lens, as the rubric's own example; the assertion no longer insists on P) |
| 9 | One plain sentence per model on the question it answers; a glossary | pass | §5.1, §5.2, §10.4 |
| 10 | `file:line` on every row; no GitHub or git writes; run evidence pending rather than fabricated | pass | three rows (R10, E2, E4) are run- or data-derived and carry their origin instead of a line; the baseline that was run is reported as interrupted, not as complete |

Eight passes and two partials, against eight of ten for the cloud run of the same test case in iteration 1.

## What the local run did that no cloud run could

- Ran the baseline and compared its intermediates byte for byte with the previous run's.
- Ran sdmTMB's `sanity()` over the 334 cached fits and refitted two months four ways (same seed, no seed, another seed) to show the seed is vestigial.
- Counted the VIIRS months with no positive cell and joined them with the fit matrix. The result is the audit's main finding, M1: 58 modelled months in 2012 to 2024 are written as all-zero maps because the satellite layer is empty, among them documented blooms with hundreds of positive samples. The science review ranks it first among the caveats and the findings log routes it to the author with options and the arithmetic untouched.
- Carried over the open items of the issue #3 plan (the positive-sample definition, the promised follow-up issue that was never opened) under their own IDs.

## Misses, and what changed in the skill because of them

1. **The baseline timing was lost.** A sanity sweep ran beside the baseline in the same session, the machine ran out of memory, and the run was killed in stage 6; the documents say so honestly and keep the 30 September log as the only clean timing. The skill now says: static work only while the baseline runs, record what else was running, and repeat an interrupted run before its timing is evidence (SKILL.md Phase 4; `references/verification.md`).
2. **A dangling reference.** The workflow review §9.2 and the run matrix cite a "run2" that exists nowhere in the documents, and the closing summary declares the audit closed while §5 steps 5 and 9 are unticked. The pre-ready check now lists dangling references (SKILL.md Phase 9).
3. **Stage 5 of the stage table names files, not a function.** The template now asks for one file and one main function per row (workflow review template §1).
4. **The outputs section does not cite `.gitignore`.** The template now asks for the citation by line (workflow review template §7).

Not changed: the lens choice for the download timeout (B, as the rubric's example), and the three rows without a line, which name a run or a data file and say so.
