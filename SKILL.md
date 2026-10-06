---
name: code-audit
description: "Audit an existing analysis repository end to end with the analyst in the loop: make it run, make it reproducible for the user, the original author and a fresh clone, and document objectives, methods, inputs, outputs, pipeline, statistics, seeds and run times. Produces three review documents (a science and objectives review in research-article form, a plain-language workflow review, and a living log of findings, recommended changes and decisions) and fixes the code through a tracked GitHub issue, branch and draft pull request with small commits split by type. Use it whenever someone wants to review, audit, clean up, document, reproduce, port, take over or hand off a whole codebase or pipeline, including their own older code, or asks to look over a repo, make it runnable by others, or find hardcoded paths, dead code, unseeded randomness or missing data instructions. Not for reviewing one diff or an open pull request (use /code-review) and not for writing new analysis code."
license: MIT
compatibility: "Runs in the main Claude Code conversation (it asks questions, pauses at checkpoints and spawns read-only subagents). A local audit needs git, the language runtime (R 4.x for R repositories) and either the gh CLI or the GitHub MCP tools. Sessions that cannot run the code use the documented degraded mode."
metadata:
  version: "0.2.0"
  author: "Holden Harris, with Claude Code"
---

# code-audit

Audit an existing analysis repository together with the analyst who asked for it. The skill has two halves that run together: a walk-through (understand, run, review, fix, verify and merge through a GitHub issue and pull request, with every decision recorded) and three review documents that the walk-through produces. It is for whole repositories or pipelines, R first but not R only. It is not for reviewing a single diff or an open pull request (use `/code-review`), and it does not write new analyses.

Paths of the form `<skill>/...` are relative to this skill's own folder (the base directory printed when the skill loads). Other paths are inside the repository being audited. Questions to the user go through the question tool (AskUserQuestion in Claude Code) when there are options to choose from, and plain prose otherwise.

## Vocabulary

- **Science review, workflow review, findings log**: the three review documents (map below): `docs/review/science-review.md`, `docs/review/workflow-review.md` and `docs/review/issueN-<slug>-log.md`. Always named in full; a bare letter is a lens.
- **Lens**: one of eight angles of review, each with a letter: P portability, R reproducibility, B bugs and fragility, D documentation, M methods and statistics, S stochasticity, T run time, E efficiency and artifacts.
- **Finding ID**: lens letter plus a number, never reused: `P1`, `R2`, `M3`.
- **Kind** (of a finding): `mechanical` (fixing it leaves outputs unchanged: paths, guards, dead code, documentation), `behavioural` (outputs change: seeding, grid template, input swap), `scientific` (what the method means changes: units, thresholds, pooling rules, parameter choices).
- **Severity**: `high` (blocks one of the three run targets or materially changes outputs), `medium` (wrong or fragile but with a workaround), `low` (tidy-up, wording).
- **Status**: `open`, `fix: step k` (findings log §5 step), `author` (handed over in the findings log §8), `issue #M` (a new issue opened from this audit), `wontfix (decision n)`.
- **Decision n**: a numbered, dated, owned line in the findings log §7. Behavioural and scientific changes need one; destructive git actions need one.
- **Commit type**: `code`, `docs`, `outputs`, `housekeeping`, `record`. One type per commit. A `record` commit changes only documents and lands before the code that relies on its evidence.
- **Sub-issue**: any new GitHub issue opened from this audit (a methods question for the author, deferred work, a scope split). Where the org profile has a decision template, methods questions use it. The findings log rows point at it as `issue #M`.
- **Root anchor**: a file at the repository root (for R, the RStudio project file) whose presence the entry point checks before doing anything, so a wrong working directory fails in one line.
- **Template mismatch**: grids or tables built on different reference templates (cell size, extent, column order) so that identical data land in different cells or rows.
- **Three run targets**: the analyst doing the audit; the original author with their existing layout and habits; a fresh clone with only the documented data placed and a local config file added.

## The contract

State this to the user at the start of a new audit and hold to it:

- **One audit = one issue, one branch, one draft pull request, three documents, commits split by type.** The documents live in the repository under `docs/review/`: `science-review.md` (the science review), `workflow-review.md` (the workflow review) and `issueN-<slug>-log.md` (the findings log; `draft-<slug>-log.md` in `review-only` mode). Repositories reviewed before this skill existed may hold the older `docs/issue*-plan.md`; treat it as a previous findings log.
- **Measure before the first code change.** A baseline run exists before any code is edited. Documents may be drafted before it. Only when no run is possible anywhere (the data no longer exists) do the committed outputs serve as the baseline, and the workflow review §9 says so.
- **Nothing scientific changes silently.** `mechanical` fixes proceed on identical-output evidence. `behavioural` fixes need a decision number and a before/after table. `scientific` items go to the original author in the findings log §8 and a sub-issue, and the arithmetic stays as it is so outputs remain comparable. When the author decides, the item becomes a `behavioural` change in this pull request with its decision number, or stays with the sub-issue for later.
- **Nothing is deleted.** Dead code, scratch files and superseded outputs move to `hoard/` (gitignored, with a README) or `archive/` (tracked, with a README table). Tracked files that should not be tracked leave the index with `git rm --cached` under a decision. History is rewritten only on the audit's own draft branch, under a decision, after confirming nobody else has pulled it (pause 9); never on a shared branch.
- **Three people must be able to run the tracked code.** Name the three run targets in the findings log §1 and check each in Phase 8.
- **The findings log is the state.** Update it before every commit. Every changed output must have a cause: a finding ID or a decision number.

## Resume rule

On any invocation in a repository that already has a findings log, and after a context compaction:

1. Read the findings log (its §0 status block first), then `git log --oneline -15` and `git status`.
2. Re-run the "where it runs" check below; a resumed session may be on a different machine.
3. Confirm the mode with the user in one line; skip the Phase 1 interview and the contract statement unless they ask.
4. Continue at the first unticked step of the findings log §5. Never redo a ticked step; re-verify only when the tree disagrees with the document.

## Modes

Detect in Phase 1 and confirm with the user:

| Mode | When | What changes |
|---|---|---|
| `audit` | A repository not reviewed this way before | Full workflow; science review, workflow review and findings log all produced |
| `fix` | One issue, one known problem | Phases 1, 2 (short), 3, 4 (smoke; baseline of the affected outputs only), 5 (only the lenses the problem touches), 6, 7, 8, 9. Findings log in its short form (appendix 1 of `<skill>/references/findings-log-template.md`). Science review and workflow review updated only where the fix changes them, and only if they exist |
| `review-only` | Documents and findings wanted, no GitHub writes and no commits (common in cloud sessions, or before deciding to proceed) | Phases 3, 7 and 9 are skipped; no `record` commits; documents go to a path the user names; findings log is `draft-<slug>-log.md` |
| `resume` | `docs/review/` holds a findings log with unticked boxes and its branch or pull request is open | Resume rule above; no new issue |
| `second audit` | A previous review was merged | New issue and new findings log (appendix 2 of its template: carry-overs from the old findings log, its "needs examination" items, open sub-issues, README caveats; closed findings confirmed in one line each, not re-listed). Science review and workflow review revised in place with a version-history line. The baseline is now the committed deliverables, so Phase 4 starts with a drift check |
| `own past code` | The user is the original author | The author target becomes the original layout on the machine that last ran it. If there is no remote, offer to create one (ask first) before Phase 3 |

Signals: `docs/review/*`, `docs/issue*-plan.md`, `CLAUDE.md`, a local config example, a setup file, branches named `N-*`, merged pull requests.

## Where it runs

Check at the start of Phase 1 and on every resume: can this session run the code (`Rscript --version` works and the data is present) and write to GitHub (`gh auth status`, or the GitHub MCP tools are available)?

- **Local session, code runnable**: everything below applies as written; GitHub writes go through `gh`.
- **Session that cannot run the code** (a cloud container without the runtime or the data): use the degraded mode.
  - Do the static work: orientation, review, document drafting, fix design. Do not edit code before the baseline results exist.
  - Every step that needs the runtime is handed off, including the smoke checks and the fingerprint snapshots: give the user a hand-off block (template in `<skill>/references/verification.md`) with the exact commands in command-line and RStudio form, where results land, and exactly which files to paste back (run log tail, environment table, fingerprint CSVs). The scripts are in this skill's `scripts/` folder; the analyst runs them from their own installed copy of the skill or from the skill's repository, and `verification.md` gives a base-R fallback for each.
  - Until results arrive, the workflow review §9 and the evidence cells in the findings log read "pending: run on the analyst's machine". Never write a run time, exit code or checksum you did not receive. The `record` commit for the workflow review §9 waits for the results. Parse what comes back; never infer it.
  - GitHub writes go through the GitHub MCP tools; `<skill>/references/github-workflow.md` maps each `gh` command to its MCP equivalent and lists the cloud limitations.
- **Either way**: subagents are read-only sweepers that return table rows with `file:line` and a quoted snippet; the main session reads each cited line before the row enters the findings log. Rows that cannot be verified are dropped, not softened.

## The three review documents

| Document | Reader and lifetime | Written in | Template |
|---|---|---|---|
| Science review, `science-review.md` | Anyone who needs to know what the pipeline does and why, in research-article form. Stable and citable; revised in place on later audits | Drafted in Phase 2, corrected in Phase 5, finalised in Phase 9 | `<skill>/references/science-review-template.md` |
| Workflow review, `workflow-review.md` | An analyst who has never seen the code and needs to run, trust and maintain it. Plain language, every term defined, as long as it needs to be | Drafted in Phase 2, filled in Phases 4 and 5, finalised in Phase 8 | `<skill>/references/workflow-review-template.md` |
| Findings log, `issueN-<slug>-log.md` (findings, recommended changes and decisions) | The analyst and the original author while the work happens; the record afterwards. Living; one per issue | Created in Phase 3 (Phase 2 in `review-only`), updated at every step | `<skill>/references/findings-log-template.md` |

Section map (titles the phases below refer to):

- **Science review**: 0 header, 1 summary, 2 objectives, 3 introduction and context, 4 data sources, 5 scientific methods, 6 results, 7 discussion, 8 references, 9 appendices.
- **Workflow review**: 0 how to read, 1 the pipeline in one page, 2 setting up and running, 3 data inputs, 4 pipeline and transformations, 5 statistical models and estimators, 6 randomness and reproducibility, 7 outputs, 8 run times and efficiency, 9 verification record (as-found and as-left), 10 appendices.
- **Findings log**: 0 status block (issue, branch, pull request, mode, reviewer, author, commit the line numbers refer to, last completed step, next step, last updated), 1 scope and targets, 2 findings register (one table per lens), 3 evidence notes, 4 recommended changes, 5 implementation plan (the checkboxes the resume rule reads), 6 change log (one row per commit), 7 decisions log, 8 needs examination (for the author), 9 acceptance criteria, 10 GitHub record, 11 closing summary.

Finding IDs tie the documents together: they appear in the findings log's registers, in commit bodies, in the workflow review §9's comparison tables and in the science review §7. Read the template before writing each document; each says what belongs in every section and shows a filled example.

## Pauses

| Pause | Where | What the user decides |
|---|---|---|
| 1 | End of Phase 1 | The scope, mode and targets as played back |
| 2 | End of Phase 2 | "Is this what the code does?" |
| 3 | Start of Phase 3 | The issue, branch name and pull request body, before the first GitHub write |
| 4 | Phase 4, before the baseline | Start the long run (or take the hand-off in degraded mode) |
| 5 | End of Phase 5 | One status per finding row |
| 6 | End of Phase 6 | The commit plan, and how often to pause in Phase 7 |
| 7 | Phase 7, each commit | Unless the user chose "run through step k" |
| 8 | Phase 7, before regenerating tracked outputs | The before/after table |
| 9 | Phase 7, before `git rm --cached`, a history rewrite or a force push | The decision number and that nobody else has pulled the branch |
| 10 | End of Phase 8 | Marking the pull request ready |

## Phase 1: setup interview

Ask and record the answers in the findings log §0-1:

1. Repository path, current branch, whether the tree is clean, the remote.
2. Original author(s) and who will review the pull request.
3. The three run targets: the analyst's machine (OS, language version), the author's layout, a fresh clone. What each needs.
4. Where the inputs that cannot ship live (a shared drive, a cloud folder, a directory junction, which is a folder that points at another folder) and which inputs those are.
5. What counts as the reference outputs (committed deliverables, a legacy run, a figure).
6. Scope limits and anything explicitly out of scope.
7. Does a GitHub issue exist? Which org profile applies (`<skill>/references/org-profiles/`; detect from `.github/ISSUE_TEMPLATE/` and the remote owner, confirm with the user, `default.md` when none fits)?
8. Mode and where this session runs.

Pause 1: play the answers back in a few lines and confirm before reading code.

## Phase 2: orientation

Read-only. Find the entry point(s), the order of operations, the configuration and the output tree. A subagent may inventory files and functions; the main session writes the prose.

Produce the first drafts of the science review §1-5 and the workflow review §1-2. Interview the author or the analyst for objectives and context the code cannot tell you, and cite where each statement comes from (file, README section, commit, paper, interview). Mark what the code does not explain as "unexplained" rather than guessing. In `review-only` mode, create the findings log now at the user's path.

Pause 2: "Is this what the code does?" Misreadings caught here are cheap; caught in Phase 7 they cost commits.

## Phase 3: GitHub scaffold

Skipped in `review-only`. Pause 3 first: show the issue title and body, the branch name and the pull request body, and wait for a yes.

1. If no issue exists, create one from the org profile's template (`<skill>/assets/issue-body.md` when the repository has no templates): context, acceptance criteria as a checklist, labels.
2. Create the branch from the issue (profile naming; default `N-slug`, where the slug is the same short phrase used in the findings log filename) and check it out.
3. Make sure `.gitignore` covers the local config file, `hoard/`, and the session files the language leaves behind (`<skill>/references/r-conventions.md` has the R list).
4. Create the findings log from its template with the status block filled; add the science review and the workflow review drafts; commit as `docs`.
5. Push and open a **draft** pull request against the default branch with `Fixes #N` and the findings log §9's checklist in the body. A draft opened early gives the author somewhere to watch and the evidence somewhere to attach. Phase 9 replaces this body with the full description and keeps `Fixes #N` and the checklist.

## Phase 4: smoke, then baseline

**Smoke first, seconds not minutes.** Root anchor present; every source file parses (`<skill>/scripts/static_sweep.R` does this without executing anything); required packages installed; required inputs present. A failure here is a finding recorded in the findings log §2 under the lens it belongs to (P for the anchor and undeclared packages, B for files that do not parse, R for missing inputs) and fixed only after the baseline exists, unless it prevents any run at all (then record it, fix the minimum, and say so in the workflow review §9's baseline notes).

Pause 4: tell the user how long the baseline is expected to take (from the README, comments or the author; say "unknown" if nothing says) and what it will touch; in degraded mode, hand off here.

**Baseline.** Run the unmodified code the way the author runs it:

- `<skill>/scripts/run_logged.R` wraps the entry point: environment header, full log, exit status, wall time, written to a folder outside the repository.
- `<skill>/scripts/snapshot_md5.R snapshot` on the tracked outputs before and after; keep a copy of the outputs outside the repository.
- `<skill>/scripts/session_capture.R` for the environment table.

Write the workflow review §9 (as-found): environment, result line (exit code, wall time), per-stage table with log evidence, the comparison with the committed outputs (output group | identical | changed | cause), and where the copy lives. Every changed file gets a cause now or a finding ID to investigate. Commit as `record` once the results exist.

While the baseline runs, start Phase 5. The invariant is "measure before the first code change", not "measure before reading".

## Phase 5: review through eight lenses

One pass over the repository, eight tables in the findings log §2. Read `<skill>/references/review-rubric.md` for what to look for in each lens, how to check it, and what evidence to record. Subagents (a cheaper model is fine) may run the sweeps; the main session verifies every row.

| Lens | Asks | Also feeds |
|---|---|---|
| P portability | Will it run on another machine? Paths, working-directory assumptions, platform-only calls, undeclared packages, missing root anchor | workflow review §2 |
| R reproducibility | Will it produce the same outputs? Inputs absent or unpinned, tracked-vs-ignored mismatches, stale outputs, template mismatches, network inputs with no fallback | workflow review §3, §9 |
| B bugs and fragility | What breaks, or passes silently? Edge cases, ignored arguments, warnings where stops belong, second-run failures | science review §6 |
| D documentation | Does the prose match the code? README vs driver, stale comments, variables that do not exist, undocumented choices | science review and workflow review throughout |
| M methods and statistics | What is being estimated, under what assumptions, and does the code do that? Models, estimators, fallbacks that drop settings, units, undocumented parameters | science review §5, §7; workflow review §5 |
| S stochasticity | Where is randomness, is it seeded, and does the seed live where it should? Side effects on global state; same-seed and cross-seed plan | workflow review §6 |
| T run time | Where does the time go, and what could be cached or skipped? Stage timings, re-run behaviour | workflow review §8 |
| E efficiency and artifacts | What is unused, duplicated or left behind? Never-called functions, never-sourced files, scratch folders, tracked files no code reads | workflow review §8 |

One problem gets one ID; choose the lens by the fix that resolves it and cross-reference another lens in the Problem cell if it applies. Also in this phase: the workflow review §3 (one subsection per input), §4 (transformations per stage, invariants, failure behaviour), §7 (outputs), and corrections to the science review §5-7.

Each register row: `ID | Where (file:line) | Problem | Kind | Severity | Status`. "None found; checked X, Y, Z" is a valid table body and more useful than silence.

Pause 5: walk the user through the registers, one status per row: `fix`, `author`, `issue #M`, or `wontfix` with a decision number. This is the longest conversation of the audit; take it in lens order and let the user batch decisions.

## Phase 6: triage and fix design

Write the findings log §4 (recommended changes: configuration keys with defaults and purpose, setup checks, the code change per finding, housekeeping, alternatives considered, constraints such as "no new dependencies beyond X; existing function signatures keep working; OS and version"), the findings log §5 (the ordered implementation plan as checkboxes, each tagged with its commit type and the IDs it closes), and the findings log §7 (decisions so far, dated and owned). Methods questions become the findings log §8 entries and sub-issues.

Pause 6: approve the commit plan. Ask which pauses the user wants in Phase 7 ("pause at every commit" or "run through step k, then show me").

## Phase 7: implement

Work the findings log §5 one step at a time:

1. Make the change. Keep function signatures backward compatible; a new argument gets a default that reproduces the old behaviour.
2. Gather the evidence the step promised: `identical()` on a table, a fingerprint match, a smoke test from the wrong directory, a missing-input table.
3. Update the findings log (tick the step, add the change-log row in §6, add any decision in §7) and the workflow review where behaviour or configuration changed.
4. Check `git status` for data or output paths that should not be committed; never `git add -A` in a repository with large data.
5. Commit as one type, subject in the profile's style (default: imperative, ending `(issue #N)`), body stating the problem, the change, the finding IDs and the evidence; add the trailer the profile asks for.
6. Pause 7 at each commit unless the user chose otherwise.

Regenerating tracked outputs is its own `outputs` commit after pause 8, and its body carries the before/after table. Moves to `hoard/` or `archive/` are `housekeeping` commits that list every file. Pause 9 before any `git rm --cached`, history rewrite or force push.

## Phase 8: verify

The three run targets, recorded in the workflow review §9 (as-left):

1. **Fresh clone without data**: must stop early with a readable table of what is missing and where to get it.
2. **Fresh clone with the data placed and a minimal local config**: must complete end to end from the command line.
3. **Independent interactive run** (the way the author works): same commit, must produce the same outputs.

`<skill>/scripts/snapshot_md5.R compare` across the runs and against the baseline; every changed output has a cause in the table. Then the convention checks: `git grep -nE "\b[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R' | grep -vE "https?://"` finds no machine paths outside commented examples; `git grep -n "windows(" -- '*.R'` is empty; `git ls-files -ci --exclude-standard` is empty. Tick the findings log §9 with the section that holds each piece of evidence; the last box is the author's sign-off and stays open. Commit as `record`.

Pause 10 before marking the pull request ready.

## Phase 9: finish

- Finalise the science review §6-7 (results; discussion with ranked caveats) and the workflow review §0 (how to read; document map).
- Offer a README and `CLAUDE.md` sync: the science review feeds "What it does", "Methods" and "Known caveats"; the workflow review feeds "Quick start", "Getting the data", "Configuration", "Outputs" and "Reproducibility"; the findings log is linked from "For collaborators". Commit as `docs`.
- Write the pull request description from `<skill>/assets/pr-description.md` (a note to the author, changes made by theme, "needs examination" from the findings log §8, "also flagged", "running it back on the original machine" with the author's exact local config); it replaces the draft body and keeps `Fixes #N` and the checklist.
- Pre-ready check on the findings log: no row still `open`, no placeholders, every unticked §5 step carried to a sub-issue, every changed output explained. Fill the findings log §11 (outcome per finding; carried-over items).
- Mark ready, request the author's review, and add the profile's records (decision log, risk register) if it has them.
- Wrap up for the user: what changed, what is waiting on whom, how to resume.

## Working rules

- Numbers go in tables with their cause next to them; prose carries the reading.
- Label honestly: "lines, not records", "features from the index file", "pending".
- A flag is a prompt for a human look, not a failure; say which it is.
- Prefer the fix that needs no new dependency; prefer the language's own functions over a shell pipe on Windows; use forward slashes.
- The author's layout keeps working: their real paths become commented examples in the local config template.
- Comments explain why; the code already says what.
- Nothing platform-only or interactive-only runs unguarded.
- Experiment scripts committed with the documents take their paths from the config or arguments and reproduce the tables they are cited for.
- When the user is terse, ask one question at a time; when they say "just do it", batch the pauses they named and keep the record exactly as full.

## Model and effort

Use the highest effort available for Phase 5 (findings), the M and S lenses, Phase 6 (fix design) and the verification reasoning in Phase 8; these are where the subtle catches happen (units, numeric tolerances, seed sensitivity, grid templates). Phases 2, 3, 7 and 9 run well at a standard effort. Delegate sweeps to a cheaper model; verification of their rows stays with the main session.

## Reference map

Read each when its phase begins:

- `<skill>/references/science-review-template.md`, `workflow-review-template.md`, `findings-log-template.md`: before writing or updating that document (science review: Phases 2, 5, 9; workflow review: Phases 2, 4, 5, 8; findings log: Phases 2 or 3, then every phase).
- `<skill>/references/review-rubric.md`: Phase 5, and the Phase 4 smoke checks.
- `<skill>/references/r-conventions.md`: Phase 3 step 3 (ignore rules) and Phases 6 and 7, for the target state of an R repository (config pattern, setup file, manifest, ignore rules, README sections); other languages use its generic part.
- `<skill>/references/github-workflow.md`: Phases 3, 7 and 9, and whenever `gh` is unavailable.
- `<skill>/references/verification.md`: Phases 4 and 8 (protocols, hand-off text, seed tests).
- `<skill>/references/org-profiles/`: Phase 1 (pick one; `default.md` when none fits).

## Scripts

Base R, Windows-safe, no shell pipes. Untested in the authoring session; the first local run is the acceptance test, so read a script before running it on a new machine.

| Script | Command | When |
|---|---|---|
| `scripts/static_sweep.R` | `Rscript <skill>/scripts/static_sweep.R <repo> [--out <dir>]` | Phase 4 smoke (parse check) and Phase 5 (function inventory, never-called, never-sourced, pattern hits) |
| `scripts/run_logged.R` | `Rscript <skill>/scripts/run_logged.R <driver.R> [--out <dir>]` | Phase 4 baseline, Phase 8 runs |
| `scripts/snapshot_md5.R` | `Rscript <skill>/scripts/snapshot_md5.R snapshot <dir> <out.csv>`; `... compare <before.csv> <after.csv> --md` | Before and after every run that writes outputs |
| `scripts/session_capture.R` | `Rscript <skill>/scripts/session_capture.R [pkg ...]` | Phase 4; cloud hand-off |
