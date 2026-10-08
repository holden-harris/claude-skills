# code-audit: quick reference

One page for the second and later uses. The full rules are in `SKILL.md`; the templates and protocols are in `references/`.

## Phases and pauses

| # | Phase | Output | Pause |
|---|---|---|---|
| 1 | Setup interview | findings log §0-1; mode; org profile; local or degraded | 1 scope: confirm the scope |
| 2 | Orientation | science review §1-5 draft; workflow review §1-2 draft | 2 orientation check: "is this what the code does?" |
| 3 | GitHub scaffold | issue, branch `N-slug`, findings log created, science and workflow reviews committed (docs), draft PR `Fixes #N` | 3 scaffold: before the first write |
| 4 | Smoke, then baseline | workflow review §9 as-found; record commit | 4 baseline go-ahead: before the long run |
| 5 | Review (8 lenses) | findings log §2 registers; workflow review §3-8; science review §5-7 corrections | 5 triage: one status per row |
| 6 | Fix design | findings log §4-5, §7 | 6 commit plan: approve it |
| 7 | Implement | one findings log §5 step per commit; findings log §6 change log | 7 commit: each commit; 8 outputs regeneration: before regenerating outputs; 9 destructive git: before `git rm --cached`, a history rewrite or a force push |
| 8 | Verify | workflow review §9 as-left; findings log §9 ticked; record commit | 10 ready for review: before marking ready |
| 9 | Finish | science review §6-7 final; README sync; PR description; findings log §11 | |

Every pause message opens with `Pause k of 10, <name> (Phase n of 9, <phase name>). You decide: <what>. Next: pause k+1, <name>.`

## Modes

`audit` full | `fix` one issue, short findings log | `review-only` no GitHub writes, no commits | `resume` continue from the findings log | `second audit` new issue and findings log, carry-overs, drift check first | `own past code` you are the author; offer to create a remote

## Documents

Science review `docs/review/science-review.md` (objectives, context, data sources, methods, results, discussion) | Workflow review `docs/review/workflow-review.md` (run it, inputs, pipeline, models, randomness, outputs, run times, verification record, glossary) | Findings log `docs/review/issueN-<slug>-log.md` (status, scope, registers, evidence, fix design, plan, change log, decisions, needs examination, acceptance, GitHub record, closing summary)

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

No `open` rows; no placeholders; every unticked §5 step carried to a sub-issue; every changed output has a cause in the workflow review §9; the findings log §11 filled; author's sign-off box left open for them.

## Resume rule

Read the findings log, then `git log --oneline -15` and `git status`; continue at the first unticked step; never redo a ticked step; re-verify only when the tree disagrees with the findings log.
