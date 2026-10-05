# code-audit

A Claude Code skill for auditing an existing analysis repository together with the analyst who owns or inherited it. It was built from three reviews of R pipelines in the WFS-FEM organisation and is written to work on any repository, in any organisation, R first but not R only.

## What it does

Two things, together:

1. **A walk-through with you.** Claude Code understands the code, runs it, reviews it through eight lenses, proposes fixes, and makes small tracked changes, pausing at ten points for your decisions. The work goes through a GitHub issue, a branch and a draft pull request, and every decision is recorded.
2. **Three review documents**, written into the repository under `docs/review/`:
   - `science-review.md` (A): what the pipeline does and why, in research-article form (objectives, context, data sources, methods, results, discussion). Stable and citable.
   - `workflow-review.md` (B): how to run, trust and maintain it, in plain language (inputs, pipeline, statistical models, randomness, outputs, run times, verification record). As long as it needs to be.
   - `issueN-<slug>-log.md` (C): the living log of findings, recommended changes, decisions and acceptance criteria. One per issue; also the state the skill resumes from.

The three standing goals of every audit: the tracked code runs for you, still runs for the original author with their layout, and runs from a fresh clone once the documented data is placed.

## Install

The source of truth is the `skills/code-audit/` folder of the WFS-FEM `Ops` repository. Clone or pull Ops, then install the folder where Claude Code looks for skills:

- **Personal skill** (available in every repository on your machine): copy or link `<your Ops clone>/skills/code-audit` to `~/.claude/skills/code-audit`. On Windows, with `C:\Repos\WFS-FEM\Ops` as the clone: `mklink /D %USERPROFILE%\.claude\skills\code-audit C:\Repos\WFS-FEM\Ops\skills\code-audit` (from an administrator prompt), or simply copy the folder and copy again after each `git pull`.
- **Project skill** (available only inside one repository, shared with its collaborators): copy the folder to `<repo>/.claude/skills/code-audit` and commit it.
- **Claude Desktop, Cowork and cloud sessions**: package the folder (`python -m scripts.package_skill skills/code-audit` from the skill-creator skill) and upload the `.skill` file in your claude.ai skills settings. Those surfaces can run the planning and documentation phases; the run and verify phases need Claude Code on a machine with the language runtime and the data.

Prerequisites on the machine that runs the audit: Claude Code; `git`; the language runtime (R 4.x for R repositories); the `gh` CLI signed in (`gh auth status`) or, in cloud sessions, the GitHub MCP tools with the repository attached for push.

## Use

Open Claude Code in the repository to audit and type `/code-audit`. The skill starts with a short interview (repository, original author, where the data lives, what counts as the reference outputs, which mode, where the session runs), then follows nine phases with pauses:

| Phase | What happens | You decide |
|---|---|---|
| 1 Setup | Interview; mode and org profile chosen | Confirm the scope |
| 2 Orientation | Reads the code; drafts Doc A §1-5 and Doc B §1-2 | "Is this what the code does?" |
| 3 GitHub scaffold | Issue, branch, C created, draft PR | Approve the first GitHub writes |
| 4 Smoke, then baseline | Quick checks; unmodified run; fingerprints of outputs | Start the long run (or run it yourself in degraded mode) |
| 5 Review | Eight lenses; findings registers; Doc B §3-8 | Triage every finding: fix, hand to the author, sub-issue, or won't fix |
| 6 Fix design | Recommended changes, commit plan, decisions | Approve the plan and how often to pause |
| 7 Implement | One commit per step, evidence in each body | Each commit (or "run through step k") |
| 8 Verify | Fresh clone, minimal config, independent run; every changed output explained | Before the PR is marked ready |
| 9 Finish | A and B finalised; README sync; PR description; closing summary | Review request to the author |

Modes: `audit` (full), `fix` (one issue, short form of C), `review-only` (documents and findings, no GitHub writes or commits), `resume`, `second audit` (a previous review was merged), `own past code` (you are the original author). The skill detects the likely mode and asks.

To resume after an interruption, type `/code-audit` again in the same repository: it reads `docs/review/`, `git log` and `git status` and continues at the first unticked step of C.

## Model and effort

Use the strongest model available for the review and fix-design phases and raise the effort there (`/effort xhigh` in Claude Code); those are where the subtle catches happen (units, numeric tolerances, seed sensitivity, grid templates). Standard effort is fine for orientation, implementation and documentation. The skill delegates read-only sweeps to a cheaper model on its own.

## When the session cannot run the code

Cloud sessions and machines without the runtime or the data run a degraded mode: all static work proceeds, and each run step is handed to you as exact commands with a list of files to paste back (run log tail, environment table, fingerprint CSVs). Nothing is written into the verification record until you paste it.

## Questions you may have

- **The repository was already audited once.** Say so; the skill opens a new issue and log, carries over what the last audit left open, confirms closed findings in a line each, and starts with a drift check against the committed outputs.
- **It is my own old code.** Pick `own past code`; the "original author" target becomes the layout on the machine that last ran it. If there is no GitHub remote, the skill offers to create one before the scaffold.
- **It is not R.** The workflow, lenses and documents are language-agnostic; the R-specific checks are marked and skipped. Add a language section to `references/review-rubric.md` and `references/r-conventions.md` if you audit a second language often.
- **Our organisation uses different GitHub conventions.** Copy `references/org-profiles/default.md` to a new profile and edit it; the skill asks which profile applies.
- **How long does an audit take?** Days, not minutes, for a pipeline with hour-long runs: the three WFS-FEM audits ran one to three days each, most of it the baseline run, the triage conversation and the fresh-clone tests.
- **Something in the skill is wrong.** Open an issue in the Ops repository with the skill's name in the title.

## Folder map

| Path | What it is |
|---|---|
| `SKILL.md` | The skill: contract, modes, phases, rules |
| `README.md` | This file |
| `docs/vignette.md` | A complete walk-through on one repository |
| `docs/quick-reference.md` | One page for the second and later uses |
| `docs/examples/` | Excerpts of finished audits with commentary |
| `references/doc-a-science-review.md`, `doc-b-workflow-review.md`, `doc-c-review-log.md` | The three document templates |
| `references/review-rubric.md` | What to look for in each of the eight lenses |
| `references/r-conventions.md` | The target state of an R repository |
| `references/github-workflow.md` | Issue, branch, PR, commit style, local vs cloud tools |
| `references/verification.md` | Smoke, baseline and verification protocols |
| `references/org-profiles/` | Organisation-specific GitHub conventions |
| `scripts/` | Four base-R helpers (fingerprints, static sweep, logged run, environment capture) |
| `assets/` | Templates copied into audited repositories (local config example, setup skeleton, hoard README, PR description, issue body, CLAUDE.md shape) |
| `evals/` | Test prompts and assertions for improving the skill (not packaged) |
