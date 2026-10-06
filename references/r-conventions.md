# R conventions: the target state after an audit

Read this in Phase 6 (fix design) and Phase 7 (implement). It describes what an analysis repository looks like when the audit is done, so that each recommended change in the findings log §4 aims at a known shape rather than at taste. Part 1 applies to any language. Part 2 is R, and lifts its patterns and code from three audited repositories (GFISHER, RedTideMaps and EcospaceBasemap); where a block is quoted, that is where it comes from.

Two rules before the list. Every change here still needs a finding ID or a decision number, and a `mechanical` change still needs identical-output evidence; the target state is not a licence to tidy. And the original author's layout keeps working: when a hardcoded path becomes a repo-relative default, the author's real path becomes a commented example in the local config template, so their first run after the merge needs one short untracked file and nothing else.

## Part 1: what any language needs

1. **Repo-relative paths, plus one local override file.** Every default in tracked code is relative to the repository root. Machine-specific values live in one gitignored file (`config.local.R`, `config.local.yml`, `.env`) with a tracked example beside it that documents every key. The driver reads the override after setting its defaults and before touching any input, so a user changes one untracked file and no tracked line.
2. **A root anchor.** The driver checks that it is running from the repository root (a project file or a marker file exists) and stops with a message that says what to do. Everything downstream is resolved from that location; without the check a wrong working directory fails forty minutes in with an error about some unrelated file.
3. **A setup step that checks dependencies and inputs before slow work.** Missing packages stop in the first second with the exact install line. Missing inputs stop before the first slow stage with a table of what is present, what is missing and how to get each one. A fresh clone without data must fail exactly this way, readably; that is the first Phase 8 test.
4. **One manifest of inputs.** A single table (key, stage that reads it, required or optional, how it is obtained, path, source) that the code, the error messages and the README "Getting the data" section all read from. Three copies of the same list drift; one cannot.
5. **Downloads that skip existing files.** A fetch helper never overwrites what is on disk unless asked (`overwrite = TRUE`), because an endpoint that serves the current compilation would otherwise quietly change a user's inputs between runs. Each download is wrapped so one unreachable server does not abort the rest, and the failure message names the page to fetch from by hand.
6. **Outputs split into tracked deliverables and ignored intermediates.** The files another project consumes are tracked and regenerated in place, so a rebuild shows in `git diff`. Heavy intermediates, caches and logs are ignored. The README names which is which.
7. **Seeds set and documented.** Every random draw is seeded through an argument whose default reproduces the committed outputs. The README says which outputs depend on the seed, and the workflow review §6 holds the same-seed and cross-seed evidence.
8. **Scratch kept in `hoard/` or `archive/`.** Nothing is deleted. Superseded code and outputs move to `archive/` (tracked, with a README table) when someone may need to read them later, or to `hoard/` (gitignored, with a README) when they only need to exist on this machine.
9. **A README with a fixed section set.** Quick start; Getting the data; Configuration; Outputs; For collaborators; Known caveats; Reproducibility. Part 2 says what each holds and which review document feeds it.
10. **Ignore rules that match the tree.** `git ls-files -ci --exclude-standard` must print nothing. A file that is tracked and also matched by `.gitignore` is a mismatch the audit resolves one way or the other: `git rm --cached` with a decision number, or a narrower rule.

## Part 2: R

### The CLAUDE.md shape

A repository that has been through the audit carries a `CLAUDE.md` with five headings, in this order: **What this is**, **Running it**, **Conventions that matter**, **Architecture notes that aren't obvious from one file**, and **Inputs, outputs, and what's gitignored**. `<skill>/assets/claude-md-template.md` has a prompt under each. The conventions section is the part that generalises. GFISHER's reads as follows, with its repository-specific names replaced by placeholders:

> - **Machine-specific paths never go in tracked files.** Defaults in the driver are repo-relative; overrides go in `config.local.R` (gitignored), documented key by key in `config.local.example.R`. Three people must be able to run the same tracked code: the original author (whose layout the defaults match), the analyst, and a fresh clone. If you add an input, add it to `fn.data_manifest()` in `R/_setup.R`, to `config.local.example.R`, and to README "Getting the data" with its size and source.
> - **Code is split by stage, one file each:** `R/<stage_1>.R` (1), `R/<stage_2>.R` (2), and so on. Don't put one stage's code in another stage's file. `R/_setup.R` is base R only and is sourced before anything else.
> - **Every stage file namespaces its calls** (`raster::`, `sf::`), and nothing needs `<heavy package>` attached. Don't add `library('<heavy package>')` to the driver; it is only used by `R/legacy/`.
> - **Nothing Windows-only or interactive-only runs unguarded.** `fn.plot_device()` opens a recording window only when `interactive()` on Windows; `plot(<template>)` in the driver is behind `if(interactive())`. Figures go to files.
> - **Stage <k> is seeded.** `fn.<stage_k>(..., seed=1)` seeds the random draws on entry. Changing or removing the seed changes <the outputs that depend on the draw> and everything downstream; <the outputs that do not> do not depend on it. Issue #<M> tracks how much that matters.
> - **Commits are split by type** (code / docs / regenerated outputs / housekeeping), subject ends with `(issue #N)`, body says why and what evidence was checked.

The skill adds a fifth commit type, `record`, for commits that change only the review documents (SKILL.md, "The contract"); say so in the repository's own list.

### Root anchor: strict or finder

Two shapes are in use. The strict anchor (GFISHER, `process GFISHER data.R`) checks the working directory and stops:

```r
# Everything downstream is resolved from the working directory, so check it first.
if(!file.exists('<Project>.Rproj'))
  stop('Set the working directory to the repo root - open <Project>.Rproj, or setwd() there. ',
       'Currently: ', getwd())
```

The finder (RedTideMaps, `run_redtide_maps.R`) also accepts `Rscript path/to/driver.R` from any directory, by reading the `--file` argument Rscript passes:

```r
# Find the repo root rather than assume the working directory: the working directory if
# it holds the .Rproj, otherwise the folder this script was launched from by Rscript.
.repo_root <- function() {
  if (file.exists("<Project>.Rproj"))
    return(normalizePath(getwd(), winslash = "/"))
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f) == 1) {
    d <- dirname(normalizePath(f, winslash = "/", mustWork = FALSE))
    if (file.exists(file.path(d, "<Project>.Rproj"))) return(d)
  }
  stop("Can't find the repo root. Open <Project>.Rproj, or setwd() to ",
       "the repo folder. Currently: ", getwd(), call. = FALSE)
}
```

Prefer the strict anchor when the author works interactively from the project file and the driver builds every path with `file.path(dir.repo, ...)` from `getwd()`; prefer the finder when the driver is also run from a scheduler or from another directory. Either way the message says what to do and prints `getwd()`. Track the `.Rproj` file (and ignore `.Rproj.user/`) so the anchor exists in a fresh clone.

### The setup file

`R/_setup.R` is base R only, so it runs before any package is attached, and is sourced once at the top of the driver, right after the anchor. It holds four things; `<skill>/assets/_setup.R` is a skeleton of them.

- `fn.check_packages(pkgs, optional)`: `requireNamespace()` over a required list and an optional list. It stops with one line the user can paste, `install.packages(c("a", "b"))`, listing only what is missing. Optional packages are reported, not required, with what they are needed for ("only for `target='smooth'`", "only for `R/legacy/`").
- `fn.plot_device()`: opens a recording window only when `interactive()` and `.Platform$OS.type == 'windows'`, inside `try()`. It replaces `rm(.SavedPlots); windows(record=T)`, which fails under `Rscript` and off Windows, and warns when `.SavedPlots` does not exist.
- `fn.data_manifest(...)`: one row per input with its resolved path. `how` has four values: `repo` (ships with the repository), `auto` (downloaded by the driver on first run), `manual` (must be obtained by hand, usually data that cannot be redistributed) and `derived` (produced by a sibling repository or supplied by the author). The `source` column is the sentence a user sees when the input is missing, so it says what the input is, roughly how big, who provides it and where to put it.
- `fn.check_inputs(manifest, stop.on.missing = TRUE)`: tests each path, prints an OK/MISSING table (`input`, `stage`, `need`, `how`, `status / path`) so a run log records what was used, prints the `source` sentence for each missing row, points at README "Getting the data" and the config example, then stops if a required input is missing. `stop.on.missing = FALSE` warns instead, for a smoke test.

The driver's order is: anchor; `_setup.R`; `fn.check_packages()`; `fn.plot_device()`; source the stage files; the SETTINGS block of repo-relative defaults; `source('config.local.R')` if it exists, with a message saying so; resolve derived paths; run any automatic download into the default folder only; `fn.check_inputs()`; then the stages. A custom input folder that is missing is reported by the input check, not downloaded into. The override step is four lines, and the message matters: a run log then records whether a local config was in play.

```r
if(file.exists('config.local.R')){
  source('config.local.R')
  message('Applied local overrides from config.local.R')
}
```

### The local config example

`config.local.example.R` is tracked; `config.local.R` is gitignored. The header says what the file is and when it is read (GFISHER):

```r
# Local path overrides for <driver.R>.
#
# Copy this file to config.local.R in the repo root and edit it. config.local.R is
# gitignored, so machine-specific paths never reach the repository. This is the only
# file you should need to touch to run the pipeline on another machine.
#
# The driver sources it AFTER setting its repo-relative defaults and BEFORE reading any
# input, so uncomment only the lines you want to change.
```

Each key is one block: a comment saying what the key is and why you would change it, a `# Default:` line that quotes the default expression, and the assignment, commented out. The author's real paths appear here as commented examples labelled as such. That is how the author's layout keeps working with a tracked file that contains no live machine path:

```r
# Folder holding the inputs that cannot ship. Point this at a shared drive or a synced
# folder to avoid keeping a second copy. (The repo default matches the author's layout.)
# Default: file.path(dir.repo, 'data', '<vintage>')
# dir.data <- 'C:/Users/<you>/<institution>/<project>/data/<vintage>'    # the author's layout
```

`<skill>/assets/config.local.example.R` is the generic version. Every key in the SETTINGS block has a block here and a row in README "Configuration"; when the audit adds a key it adds all three in the same commit.

### Manifest columns, drift and provenance

EcospaceBasemap's `R/data_setup_functions.R` is the fuller manifest, for a repository whose inputs are mostly downloaded. Its columns are `key`, `section`, `path` (relative to `dir.data`), `type` (how presence is tested: `file`, `dir.shp`, `dir.asc`, `dir.any`, `gdb`), `required`, `how`, `pull` (the fetch function, `NA` for repo and manual), `pull.dir`, `url`, `terms` (the redistribution note) and `expects` (the shape on disk). Its header says why it exists: "the single place that records what those inputs are, where they come from, and what shape they have to be in on disk, so the driver, its error messages and the README cannot drift apart." Four helpers around it are worth copying whenever inputs come from endpoints that are not pinned:

- `fn.reference_counts()`: a named vector of item counts measured on the copies that produced the verified outputs. The file calls it "a tripwire, not a specification": a provider revising a layer is legitimate, so a mismatch prints `DRIFT` and one warning, and the run continues. Update a value only alongside a run that shows the new data still produces a sensible output, and say so in the commit.
- `fn.input_fingerprint()`: count, bytes and the MD5 of the primary file, base R only. Shapefiles report features from the `.shx` index, `(size - 100) / 8`; CSVs report **lines, not records**, because no cheap base R method reproduces `read.csv()`'s record count on files with embedded newlines, "and a number that is quietly wrong is worse than one that is honestly labelled". Print the unit next to the number.
- `fn.record_provenance()`: appends date, input, count, unit, bytes, MD5 and URL to `data/PROVENANCE.tsv` for each download. The file is gitignored because it describes this working copy; committing it would mean merge conflicts over machine-specific facts. The shared reference is `fn.reference_counts()`, which is tracked.
- `fn.pull_all(dir.data, overwrite = FALSE)`: runs every `auto` download still needed, skips what is present ("already present, skipping"), wraps each in `try()` so one dead server does not abort the rest, raises the download timeout, and records provenance for what arrived. The README wording to reuse is in EcospaceBasemap's "For collaborators" and "Getting the data": "Your paths are yours", "Downloads never overwrite what you already have", "Knowing which vintage you hold", and the sentence that explains the whole mechanism: two people can run identical code, see identical console output, and work from different inputs.

The loop body of `fn.pull_all()` is the shape to copy: skip, then `try()`, then say where to get it by hand.

```r
if (!overwrite && isTRUE(fn.input_found(row, dir.data)$present)) {
  message(sprintf("%-24s already present, skipping", row$key))
  next
}
res <- try(do.call(row$pull, list(dir.target)), silent = TRUE)
if (inherits(res, "try-error"))
  warning(sprintf("%s failed to download: %s\n  Obtain it by hand from %s",
                  row$key, conditionMessage(attr(res, "condition")), row$url), call. = FALSE)
```

The timeout pattern itself, from GFISHER's `fn.pull_dbseabed()`:

```r
op <- options(timeout = max(3600, getOption('timeout')))   # the default 60 s can be too short
on.exit(options(op), add = TRUE)
```

### Ignore rules

`.gitignore` is grouped and commented, and it names the tracked deliverables in a comment so a reader knows what is deliberately not ignored. GFISHER's groups: machine and session files; inputs that cannot ship; generated outputs, with the tracked deliverables named; author scratch, which is where `hoard/` sits. The R session files to list (this is the list Phase 3 refers to):

```
.Rhistory
.RData
.Ruserdata
.Rapp.history
.Rproj.user/
Rplots.pdf          # written by a non-interactive Rscript run if any plot() escapes the interactive() guard
config.local.R      # machine-specific overrides; copy config.local.example.R to create one
hoard/              # author scratch, never committed
.DS_Store
```

When deliverables sit inside an otherwise ignored tree, ignore the tree and negate the deliverables, directory by directory (RedTideMaps):

```
# Generated outputs: track the deliverables (ecospace_ascii/, plots/) but not the
# heavy intermediates (sdm/, clipped/, combined/, run logs).
out/**
!out/*/
!out/*/ecospace_ascii/
!out/*/ecospace_ascii/**
!out/*/plots/
!out/*/plots/**
```

A negation only takes effect if every parent directory on the way is also un-ignored, which is why the pattern re-adds `out/*/` first. The rule the audit checks in Phase 8: `git ls-files -ci --exclude-standard` is empty, meaning nothing tracked is also ignored. GFISHER's housekeeping commit put it as "what is tracked is exactly what is not ignored".

### `hoard/` and `archive/`

`archive/` is tracked and has a README with a `File | Notes` table, one row per file, saying what each was and what superseded it. RedTideMaps' `archive/README.md` is the model: the monthly monolithic scripts, "Last pre-refactor copy", "will not work against the refactored function files". Put something here when a reader may need it: a legacy driver that older runs were made with, a superseded method kept for comparison.

`hoard/` is gitignored and never committed. Its README (`<skill>/assets/hoard-README.md`) says what was moved there, from where, by which housekeeping commit, and that nothing in it is read by the pipeline. Put something here when it only needs to exist on this machine: one-off scripts, baseline copies of outputs taken before a change, scratch. The housekeeping commit that moves files lists every one in its body, so the record survives even though the files do not travel.

### Shipped public data and experiment scripts

Public data small enough to track ships with the repository, with a `SOURCE.md` beside it: origin URL, citation, the date it was downloaded, and any processing between the download and the file on disk (GFISHER `data/dbseabed/SOURCE.md` and `data/seagrass/SOURCE.md`). Shipping removes a network dependency; GFISHER shipped the dbSEABED grids after the provider's server was unreachable during the fresh-clone test, which would have blocked stage 1 for every new user. The download helper stays as a fallback and the manifest row becomes `repo`.

Experiment scripts committed with the review documents (`docs/issueN_<what>.R`) follow the same rules as the pipeline: paths from the config or from arguments, no `setwd()`, outputs written next to the script (`docs/issueN_<what>_summary.csv`), and they reproduce exactly the numbers the science review or the findings log cite them for. A script that only ran once on the analyst's machine is evidence nobody else can check.

### README section set

The three audited repositories converge on seven sections; GFISHER, the most recent audit, has all seven under these names. Older READMEs name them differently ("Inputs" for "Getting the data", "Output tree" for "Outputs", a configuration table under "For collaborators"). The audit renames to the set below and keeps any extra sections the repository already has (a per-stage walk-through, a verification table against legacy outputs).

| Section | Holds | Fed by |
|---|---|---|
| Quick start | Open the project file or `setwd()`; the install line; get the data; the one command (interactive and `Rscript` forms). Show the input-check table a run prints, so a user recognises it | workflow review §2 |
| Getting the data | Everything the pipeline reads: a table of input, size, how (ships / downloads itself / by request) and where it goes; the expected `data/` tree with tracked and gitignored marked; what happens without each optional input; how to point at an existing copy instead of duplicating it | workflow review §3 |
| Configuration | A `Key / Default / Purpose` table for every key in the SETTINGS block; where the file is sourced; the author's own config described in one sentence | workflow review §2, findings log §4 |
| Outputs | The output tree; which are tracked deliverables and which are ignored; what overwrites in place and why | workflow review §7 |
| For collaborators | Your paths are yours; downloads never overwrite what you already have; contributing changes (branch from the issue, `(issue #N)` subjects, pull request with `Fixes #N`, commits split by type); a link to the review documents | findings log |
| Known caveats | Numbered, ranked by how much each could affect a result, each citing the stage and the evidence | science review §7 |
| Reproducibility | Tested environment (R version, OS, date); the byte-identity statement, in the form "a fresh clone with only `config.local.R` added runs end to end under `Rscript`; stage 1 outputs regenerate byte-identical given the same inputs, verified on a second machine on <date>; stages 2 to 4 are deterministic given `seed`"; the `tools::md5sum()` one-liner | workflow review §9 |

### Other R rules seen in these repositories

- **Namespace every call in stage files** (`raster::`, `sf::`) so a file does not depend on what the driver attached, and do not attach a heavy package for the sake of one legacy module.
- **Nothing Windows-only or interactive-only runs unguarded.** `windows()`, `dev.new(record=TRUE)`, `choose.dir()`, `View()` and bare `plot()` calls in a driver go behind `if(interactive())` or into `fn.plot_device()`; figures go to files. `git grep -n "windows(" -- '*.R'` is empty at the end of the audit.
- **Seeds are arguments.** `fn.stage(..., seed = 1)` with `if(!is.null(seed)) set.seed(seed)` on entry: a fixed integer reproduces run to run, `NULL` restores the unseeded behaviour, and the default reproduces the committed outputs. Never `set.seed()` at file scope in a sourced function file: it seeds whatever happens to run next and is reset on every re-source. Record one as an S finding.
- **Raise the download timeout and restore it** with `options(timeout = ...)` and `on.exit(options(op), add = TRUE)`, as above. The default 60 s aborts a 200 MB archive on an ordinary connection, and the first cold clone is usually the first time the download has ever run.
- **Roxygen headers on every function**, `#'` with `@param` and `@return`, even without a package. They are the function's contract and what a reader sees first, and they make a later package conversion mechanical. The comment explains why; the code already says what.
- **No `rm(list=ls())` and no `setwd()` in tracked code.** The workspace wipe destroys whatever the user set interactively, and `Rscript` starts clean anyway; `setwd()` is what the root anchor and `file.path(dir.repo, ...)` replace. Functions take paths as arguments and return their result rather than assigning with `<<-`.
- **`dir.create(path, recursive = TRUE, showWarnings = FALSE)`**, because without `recursive` it warns and creates nothing when a parent is missing, and the write that follows fails with a message about the file instead of the folder.
- **`writeRaster(..., overwrite = TRUE)`**, and the equivalent for every other writer, so a second run in the same tree works. A pipeline that only runs once on a clean folder is not reproducible, it is untested.
- **`tools::md5sum()` instead of a shell pipe** for checksums, and `file.path()` with forward slashes instead of pasted separators: both run on Windows without a shell, which is where the author usually works.
### Checks that confirm the target state

Run these in Phase 8 and record each in the findings log §9 with the section that holds its evidence; GFISHER's portability commit cites the first three as "smoke-tested three ways".

- With a two-line `config.local.R` pointing at the data: the input table prints all `OK` and the run completes.
- From the wrong directory: the driver stops at the anchor, and the message names the project file and prints `getwd()`.
- With a bogus `dir.data` in a throwaway `config.local.R`: the `MISSING` table prints, the `source` sentences follow, and the driver stops before the first slow stage.
- A second run in the same tree completes: every writer has `overwrite = TRUE` and every `dir.create()` is recursive.
- `Rscript <skill>/scripts/static_sweep.R <repo>`: every file parses; no never-sourced file remains outside `archive/` and `hoard/`.
- `git grep -nE "[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R'`: nothing outside the commented examples in `config.local.example.R`.
- `git grep -n "windows(" -- '*.R'`: empty.
- `git ls-files -ci --exclude-standard`: empty.

### Commit style

Imperative subject ending `(issue #N)`, for example "Make the driver's paths portable and check inputs up front (issue #2)". The body has three parts, in prose or a short list: the problem (what was wrong and for whom), the change (file by file when more than one), and the evidence (what was run, what was compared, which finding IDs close). One type per commit: `code`, `docs`, `outputs` (regenerated deliverables, with the before/after table in the body), `housekeeping` (moves, untracking, ignore rules, every file listed) and `record` (review documents only, landing before the code that relies on their evidence). `<skill>/references/github-workflow.md` has the full workflow: branch naming, the draft pull request, trailers the org profile asks for, and the `gh` commands with their MCP equivalents.
