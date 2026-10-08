<!-- Template for the target repository's CLAUDE.md. This asset is deliberately not named
     CLAUDE.md, so that Claude Code does not load it as instructions when the skill loads;
     copy it to <repo>/CLAUDE.md in Phase 9 and fill it in. Keep the result under about
     80 lines: Claude Code reads it on every invocation, and README.md holds the long form.
     The five headings are the ones GFISHER's CLAUDE.md settled on after its audit. -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

- Two or three sentences: what the pipeline turns into what, and for whom.
- Whether there is a build system, package or test suite. Usually none: one driver plus one file per stage, run interactively or with `Rscript`.
- Point to `README.md` for inputs, configuration, outputs and caveats, and to `docs/review/` for the audit documents and their findings.

## Running it

- The one command, or the two steps (open the `.Rproj`, then source the driver). Name the entry point.
- The order of events in one sentence: root-anchor check, setup file, stage files sourced, SETTINGS defaults, local config sourced, derived paths resolved, downloads if absent, input check, then the stages.
- How long a full run takes and which stage dominates.
- The R version, the required packages, and the optional ones with what each is only needed for.

## Conventions that matter

- Bullets, each bold-led, each a rule with its reason. Start from the generalised list in `<skill>/references/r-conventions.md` and make every placeholder specific.
- Machine-specific paths never go in tracked files, and the three people who must be able to run the same code.
- Code split by stage, one file each; namespaced calls and what must not be attached.
- Nothing Windows-only or interactive-only unguarded; which stage is seeded, what the seed changes and what it does not.
- Commits split by type with `(issue #N)` in the subject.

## Architecture notes that aren't obvious from one file

- What a reader cannot see from the file in front of them: a legacy module that is superseded but not dead, and why it is kept.
- An invariant (layers sum to 1; one grid template shared by every raster) and where it is enforced.
- A variable that shadows a function; a parameter whose value has a reason (a depth cut-off because nothing was observed deeper); a table that holds presence records only.
- Cite the file and function for each, and say what breaks silently if it is changed.

## Inputs, outputs, and what's gitignored

- One bullet per input group: cannot ship (why, size, which config key locates it); public and tracked, with its provenance file; ships with the repo; tracked but optional at run time, and what happens without it.
- The tracked outputs (the deliverables, and whether a stage overwrites them in place so a rebuild shows in `git diff`).
- The gitignored outputs, and anything a past audit untracked that remains only in history.
