# code-audit: quick reference

One page for the second and later uses. The full rules are in `SKILL.md`; the templates and protocols are in `references/`.

## Phases and pauses

| # | Phase | Output | Pause |
|---|---|---|---|
| 1 | Setup interview | Doc C §0-1; mode; org profile; local or degraded | 1 confirm scope |
| 2 | Orientation | Doc A §1-5 draft; Doc B §1-2 draft | 2 "is this what the code does?" |
| 3 | GitHub scaffold | issue, branch `N-slug`, C created, A/B committed (docs), draft PR `Fixes #N` | 3 before the first write |
| 4 | Smoke, then baseline | Doc B §9 as-found; record commit | 4 before the long run |
| 5 | Review (8 lenses) | Doc C §2 registers; Doc B §3-8; Doc A §5-7 corrections | 5 triage per row |
| 6 | Fix design | Doc C §4-5, §7 | 6 approve the commit plan |
| 7 | Implement | one Doc C §5 step per commit; Doc C §6 change log | 7 each commit; 8 before regenerating outputs; 9 before destructive git |
| 8 | Verify | Doc B §9 as-left; Doc C §9 ticked; record commit | 10 before marking ready |
| 9 | Finish | Doc A §6-7 final; README sync; PR description; Doc C §11 | |

## Modes

`audit` full | `fix` one issue, short C | `review-only` no GitHub writes, no commits | `resume` continue from C | `second audit` new issue and C, carry-overs, drift check first | `own past code` you are the author; offer to create a remote

## Documents

A `docs/review/science-review.md` (objectives, context, data sources, methods, results, discussion) | B `docs/review/workflow-review.md` (run it, inputs, pipeline, models, randomness, outputs, run times, verification record, glossary) | C `docs/review/issueN-<slug>-log.md` (status, scope, registers, evidence, fix design, plan, change log, decisions, needs examination, acceptance, GitHub record, closing summary)

## Findings

Row: `ID | Where (file:line) | Problem | Kind | Severity | Status`

Lenses: P portability, R reproducibility, B bugs and fragility, D documentation, M methods and statistics, S stochasticity, T run time, E efficiency and artifacts

Kind: `mechanical` (outputs unchanged) | `behavioural` (outputs change; needs a decision and a before/after table) | `scientific` (meaning changes; to the author, arithmetic untouched)

Severity: `high` blocks a run target or materially changes outputs | `medium` wrong or fragile with a workaround | `low` tidy-up

Status: `open` | `fix: step k` | `author` | `issue #M` | `wontfix (decision n)`

## Commits

Kinds: `code`, `docs`, `outputs`, `housekeeping`, `record` (documents only; lands before the code that relies on its evidence). Subject imperative, default suffix `(issue #N)`. Body: problem, change, IDs closed, `Evidence:` line, "Left out, deliberately:" when relevant. Check `git status` for data and output paths before every commit; never `git add -A` with large data.

## Commands

```
Rscript <skill>/scripts/static_sweep.R <repo> [--out <dir>]            # parse check + inventory (Phases 4, 5)
Rscript <skill>/scripts/run_logged.R <driver.R> [--out <dir>]          # logged baseline run (Phases 4, 8)
Rscript <skill>/scripts/snapshot_md5.R snapshot <dir> <out.csv>        # fingerprints before and after
Rscript <skill>/scripts/snapshot_md5.R compare <before.csv> <after.csv> --md
Rscript <skill>/scripts/session_capture.R [pkg ...]                    # environment table
git grep -nE "[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R'    # machine paths (commented examples only)
git grep -n "windows(" -- '*.R'                                        # must be empty
git ls-files -ci --exclude-standard                                    # must be empty
```

## Pre-ready check (Phase 9)

No `open` rows; no placeholders; every unticked §5 step carried to a sub-issue; every changed output has a cause in Doc B §9; Doc C §11 filled; author's sign-off box left open for them.

## Resume rule

Read C, then `git log --oneline -15` and `git status`; continue at the first unticked step; never redo a ticked step; re-verify only when the tree disagrees with C.
