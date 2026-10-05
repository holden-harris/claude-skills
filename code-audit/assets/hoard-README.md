# hoard/

Scratch that is kept but not tracked. Nothing in this folder is read by the pipeline.

**What goes here.** One-off scripts, superseded outputs, baseline copies of outputs taken before a change, and anything else the audit moved out of the way rather than deleted. The rule is that nothing is deleted: a file either stays where code reads it, moves to `archive/` because someone may need to read it later, or moves here.

**Why it is gitignored.** `hoard/` is listed in `.gitignore` under author scratch, so it exists only in this working copy. Nothing here reaches a clone, a pull request or a collaborator's machine, which is the point: it can hold large, half-finished or machine-specific files without a `git rm --cached` later.

**How it differs from `archive/`.** `archive/` is tracked and has a README with a `File | Notes` table, because its contents are still worth reading (a pre-refactor copy of the driver, a superseded method kept for comparison). `hoard/` is for things that only need to exist on this machine, for this person, for now. If you want to share something from here, move it to `archive/` and add a row to its table in the same commit.

**When to empty it.** Any time. Nothing here is needed to run the pipeline, and the housekeeping commit already records what was moved. Check the table first so a baseline copy you still want to compare against is not lost.

Moved here by the issue #N housekeeping commit on <date>; nothing here is read by the pipeline. The commit body lists the same files, so the record survives even though these files do not travel.

| File | Moved from | Why |
|---|---|---|
| `<script>.R` | `<original path>` | One-off script; superseded by `<function>` in `R/<stage>.R` |
| `<output>.asc` | `<original path>` | Baseline copy taken before <change>; compare with `tools::md5sum()` |
| `<folder>/` | `<original path>` | Scratch outputs from an abandoned approach; see Doc C §7 decision <k> |
