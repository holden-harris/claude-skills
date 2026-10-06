# Review rubric: the eight lenses

Read this when Phase 5 begins, and for the smoke checks when Phase 4 begins. It says what to look for under each lens, how to check it in a cloud session (Grep) and locally (base R or one of the skill's scripts), what evidence a row needs, which kind a finding usually has, and shows real rows from audited repositories.

## How to use it

- One pass over the repository, eight tables in Doc C §2, in lens order: P portability, R reproducibility, B bugs and fragility, D documentation, M methods and statistics, S stochasticity, T run time, E efficiency and artifacts.
- Subagents may run the sweeps and return candidate rows. The main session reads every cited line before a row enters the register; a row that cannot be verified is dropped, not softened.
- Each row is `ID | Where (file:line) | Problem | Kind | Severity | Status`. IDs are the lens letter plus a number (P1, R2) and are never reused. Kind is mechanical, behavioural or scientific; Severity is high, medium or low; Status is `open`, `fix: step k`, `author`, `issue #M` or `wontfix (decision n)`.
- "None found; checked X, Y, Z" is a valid table body, because it tells the next reader what was looked at.
- The Grep patterns are regexes for the Grep tool with a file glob. Exclude matches inside `https?://` URLs and in commented examples (the local config template's `# dir.data <- "C:/..."` lines) before counting a hit. The local commands are base R or the skill's four scripts: `<skill>/scripts/static_sweep.R`, `snapshot_md5.R`, `run_logged.R`, `session_capture.R`.
- Example rows come from three repositories cloned beside this skill: EcospaceBasemap (commit `3d97024`), GFISHER (`62f7a08`; pre-fix lines are marked `@3e4dea1` and read with `git show 3e4dea1:<path>`, and "plan doc" is its `docs/issue2-review-gfisher-repo-plan.md`) and RedTideMaps (`a875d64`). Status cells follow the repository's own review document where one records them and are illustrative otherwise. Login names and institutions inside quoted code are replaced by placeholders such as `<author>`.

## Contents

1. Phase 4 smoke checklist
2. P portability
3. R reproducibility
4. B bugs and fragility
5. D documentation
6. M methods and statistics
7. S stochasticity
8. T run time
9. E efficiency and artifacts
10. Cross-lens rules

## Phase 4 smoke checklist

Seconds, not minutes: each check finishes before the baseline starts, so a problem that would end a 16-minute run is found first. Record a failure as a row in Doc C §2 under the lens it belongs to (P for the anchor and undeclared packages, B for files that do not parse, R for missing inputs) and fix it after the baseline exists, unless it prevents any run at all; then record it, fix the minimum, and say so in the baseline notes. One problem, one row: its Status points at the step that fixes it.

| Check | How | What failure looks like |
|---|---|---|
| Root anchor present | A file at the repository root (the RStudio project file, or whatever the entry point tests) whose presence the driver checks before anything else. `Grep "file\.exists\(['\"][^'\"]*\.Rproj" --glob "*.R"` finds the check; `ls <repo>/*.Rproj` finds the file; run the driver from a wrong directory and from the root (EcospaceBasemap `make_WFS_basemaps.R:19-21` is the strict form) | No check, so the driver assumes `getwd()` is the root and fails on the first relative path; or the anchor file is gitignored and a fresh clone has nothing to check against |
| Every source file parses | `Rscript <skill>/scripts/static_sweep.R <repo>` parses each file without executing anything. Without the script: `Rscript -e 'for (f in list.files(".", "\\.[Rr]$", recursive = TRUE)) tryCatch(parse(f), error = function(e) cat(f, conditionMessage(e), "\n"))'` | `<file>:<line>:<col>: unexpected symbol`, or `unexpected end of input` from an unclosed brace; one unparseable file ends `source()` for the whole driver |
| Required packages installed | The repository's own check if it has one (GFISHER `fn.check_packages()`, `R/_setup.R:18`); else collect the declared list with `Grep "library\(\|require\(\|requireNamespace\(\|[A-Za-z0-9.]+::" --glob "*.R"` and run `Rscript -e 'print(setdiff(c(<list>), rownames(installed.packages())))'` | `Error in library(x) : there is no package called 'x'`, often minutes in; a package used through `::` but listed nowhere is noted in the same row |
| Required inputs present | The repository's manifest if it has one (EcospaceBasemap `fn.check_inputs()`, `R/data_setup_functions.R:318`); else list what the driver reads with `Grep "read\.csv\(\|read_csv\(\|st_read\(\|read_sf\(\|rast\(\|raster\(\|readRDS\(\|load\(\|read_excel\(" --glob "*.R"` and `file.exists()` each path | `cannot open file '...': No such file or directory` deep inside a stage; note which stage and how long it ran first (GFISHER P4 @3e4dea1: a missing survey file failed inside stage 2 after stage 1 had run for minutes) |

A pass reads: anchor OK, `n` files parsed with 0 errors, packages OK, inputs OK. In a session without the runtime, hand the four commands to the analyst as a block (command line and RStudio variants, what to paste back) and write "pending: run on the analyst's machine" in the rows until the output arrives.

## P portability

Asks: will it run on another machine? Feeds Doc B §2.

**What to look for**
- Absolute paths to one person's machine: drive letters, home folders, synced-drive folders, temp folders.
- Working-directory assumptions: `setwd()`, paths relative to wherever the author happened to be, no root anchor.
- Platform-only or interactive-only calls run unguarded: graphics devices, file choosers, shell commands, backslash paths, file names that only resolve on a case-insensitive disk.
- Packages used but declared nowhere a newcomer would read, or declared but not installed; system dependencies (Java, GDAL, a compiler) nobody mentions.
- Branching on the user name or host name to pick paths, which works for exactly the people listed.
- Workspace wipes at the top of a driver, which break anything that sources the driver from another script.

**How to check**
- Cloud: `Grep "\b[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" --glob "*.R"` (repeat for `*.r`, `*.Rmd`, `*.py`, `*.md`), dropping `https?://` hits and commented examples. `Grep "setwd\(|choose\.dir\(|file\.choose\(|Sys\.info\(\)\[\[?.user|Sys\.getenv\(.(USER|USERNAME)" --glob "*.R"`. `Grep "windows\(|x11\(|quartz\(|shell\(|system\(.cmd|\\\\\\\\" --glob "*.R"` for platform-only calls. `Grep "rm\(list ?= ?ls\(\)\)" --glob "*.R"`.
- Local: `Rscript <skill>/scripts/static_sweep.R <repo>` lists the pattern hits and the package names each file uses; compare with `rownames(installed.packages())` and with the README's list. `git grep -nE "[A-Za-z]:/|/Users/|/home/|OneDrive|AppData" -- '*.R'` is the same sweep over tracked files only.

**R specifics**
- `library()` order matters when two packages export the same generic (`raster` and `terra`, `sp` and `sf`); note where the attach happens relative to the `source()` of function files.
- `windows()`, `dev.new(record = TRUE)` and `.SavedPlots` exist only in Windows RGui, and `choose.dir()` is Windows-only; guard them with `interactive() && .Platform$OS.type == "windows"`.
- Packages that need Java (`xlsx`, `rJava`) fail on a machine without it; `readxl` reads the same sheets without it.
- The `.Rproj` file is the natural root anchor; it must be tracked, with `.Rproj.user/` ignored.

**Evidence to record**: the quoted line, who it works for (the author only, Windows only) and which stage needs it. No measurement; the Phase 8 wrong-directory and fresh-clone runs are the proof of the fix.

**Kind guidance**: nearly always mechanical, because a path or a guard does not change a number. Moving a wipe or a `library()` call is mechanical only if the stage outputs stay identical, so run the comparison. A documentation-only fix (listing the packages) is mechanical.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| P1 | GFISHER `process GFISHER data.R:26` @3e4dea1 | `dir.ecospace.maps <- "C:/Users/<author>/OneDrive - <institution>/.../Ecospace/maps"`; required by stage 1 | mechanical | high | fix: step 3 |
| P3 | GFISHER `process GFISHER data.R:1,105` @3e4dea1 | `rm(list=ls());rm(.SavedPlots);graphics.off();gc();windows(record=T)`: wipes the workspace, warns when `.SavedPlots` is absent, fails off Windows | mechanical | medium | fix: step 3 |
| P5 | GFISHER `docs/issue5_seed_experiment.R:4,6` | `setwd('C:/Repos/WFS-FEM/GFISHER')` and `E <- 'C:/Users/User/AppData/Local/Temp/gfisher_baseline/exp_issue5'` in a tracked experiment script, although `CLAUDE.md:22` says machine-specific paths never go in tracked files | mechanical | low | open |
| P2 | EcospaceBasemap `make_WFS_basemaps.R:12` | `rm(list=ls());graphics.off();gc()` opens the driver, so sourcing it from another script loses that script's state; the anchor check at `:19-21` is the pattern to keep | mechanical | low | open |
| P4 | RedTideMaps `scripts/old scripts/polygon_clipping_rt.R:18-25` | `if (user == "<author>") { wd <- "C:/Users/<author>/OneDrive - ..." } else if (user == "<second user>") {...}`: paths branch on the login name and a third user gets `choose.dir()`; superseded file, so the fix is the move in E4 | mechanical | low | open |

## R reproducibility

Asks: will it produce the same outputs? Feeds Doc B §3 and §9.

**What to look for**
- Inputs absent from the repository with no manifest saying what they are, where they come from, their size and vintage.
- Network inputs fetched on every run with no cached copy and no fallback, so a server change or outage changes or stops a stage.
- Tracked-versus-ignored mismatches: outputs or data tracked although `.gitignore` matches them; deliverables nothing regenerates; stale output folders.
- Grid or template mismatches: committed outputs built on a different template (cell size, extent, NODATA) than the code now uses.
- No record of the environment: language version, package versions, OS; no `sessionInfo()` or lock file anywhere.
- Date-stamped or run-stamped file names, which make every run look different.

**How to check**
- Cloud: `Grep "download\.file\(|url\(|curl|httr|GET\(|fromJSON\(.https?|read\.csv\(.https?|getNOAA|read_sf\(.https?" --glob "*.R"` for network inputs, then check each against the manifest and for a `file.exists()` skip. `Grep "sessionInfo\(|renv|packageVersion\(|R\.version" --glob "*.{R,md}"` for environment capture. `Grep -i "^cellsize|^xllcorner|^ncols|^nodata" --glob "**/*.asc"` and compare the header values across files. `Grep "Sys\.Date\(\)|Sys\.time\(\)|format\(Sys" --glob "*.R"` for stamped names.
- Local: `git ls-files -ci --exclude-standard` (tracked but ignored; should be empty); `git ls-files | grep -E '\.(asc|tif|csv|rds|RData|png|pdf)$'` for tracked outputs, then ask which code writes each. `Rscript <skill>/scripts/snapshot_md5.R snapshot <outputs> before.csv` before the baseline and `... compare before.csv after.csv --md` after it; every changed file gets a cause or a finding ID. `Rscript <skill>/scripts/session_capture.R <pkgs>` gives the environment table for Doc B §9.

**R specifics**
- `renv.lock` or a `sessionInfo()` dump in the run log is the minimum; package versions change raster headers (`CELLSIZE` precision), CRS strings and `sf` geometry handling.
- `download.file()` has a 60-second default timeout (`options(timeout)`); raise it around large downloads and treat a failed download as a missing input, not a crash.
- `writeRaster()` writes `.asc` headers with the package's own precision; compare headers, not just values.

**Evidence to record**: for a missing or network input, what it is and the sentence a newcomer needs to get it (goes to Doc B §3); for a mismatch, the two values side by side (`CELLSIZE 0.0833333333329999` against the exact 1/12 degree) and the count of cells or rows affected, in Doc C §3; for the environment, the table from `session_capture.R`.

**Kind guidance**: adding a manifest, a cache or an environment record is mechanical. Swapping an input source or regenerating outputs on the correct template is behavioural (outputs change) and needs a decision number. A row that only documents an input's provenance is mechanical.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| R1 | EcospaceBasemap `make_WFS_basemaps.R:66` | `depth = getNOAA.bathy(lon1=bbox[1],...,resolution=res)`: live download on every run, not in `fn.data_manifest()` (`R/data_setup_functions.R:42`), no cached copy, so stage 1 depends on the server being up and unchanged (a cache also removes the download time; no separate T row) | mechanical | medium | open |
| R2 | EcospaceBasemap, repository-wide | No `sessionInfo()`, `renv.lock` or package-version record anywhere; `Grep "sessionInfo\|renv" --glob "*.{R,md}"` finds nothing. Checked `make_WFS_basemaps.R`, `R/*.R`, `README.md`, `.gitignore` | mechanical | low | open |
| R3 | GFISHER `.gitignore` vs `git ls-files` (plan doc `:64`) | 30 output files and 97 geodatabase files tracked although `.gitignore` matches them; two legacy geodatabases (about 200 MB) referenced by no code | mechanical | medium | fix: step 9 (decision 3) |
| R5 | GFISHER `output/affinity_selratio_mice/GFISHER_survey_effort_5min_66x78.asc` (plan doc `:66`) | Committed effort raster built on a template whose header has `CELLSIZE 0.0833333333329999` while the depth grid carries the exact 1/12 degree; seven stations on a row boundary fall differently. Found by the baseline run (plan doc §4.1) | behavioural | medium | fix: step 8 |
| R6 | GFISHER `data/dbseabed/` (plan doc `:313`) | Found by the fresh-clone test on 2 Oct 2026: the server hosting the self-downloading dbSEABED grids did not respond, so a clone could not run; the four grids now ship with provenance in `SOURCE.md` | mechanical | high | fix: step 10 (decision 6) |

## B bugs and fragility

Asks: what breaks, or passes silently? Feeds Doc A §6.

**What to look for**
- Second-run failures: writers without an overwrite flag, non-recursive directory creation, files appended to rather than replaced.
- Edge cases that pass silently: comparisons on data with NA, a filter that drops the rows it was meant to treat, a zero-length result indexed with `[1]`.
- Arguments accepted but never read; defaults that disagree with what the driver passes.
- Warnings where stops belong: count mismatches that only print, errors swallowed by a silent `try()` with no check of the result.
- Lookups by pattern (`grep()` on layer names, `list.files()[1]`) with no check for zero or several matches.
- Network calls with the default timeout and no retry or fallback.

**How to check**
- Cloud: `Grep "writeRaster\(|write\.csv\(|write_csv\(|saveRDS\(|ggsave\(|pdf\(|png\(" --glob "*.R"`, then read each call for `overwrite`; `Grep "dir\.create\(" --glob "*.R"` for `recursive = TRUE`. `Grep "which\(|== *NA|!= *NA" --glob "*.R"` where the column can hold NA. `Grep "try\(|tryCatch\(|suppressWarnings\(|suppressMessages\(|silent *= *T" --glob "*.R"` and read what happens to the result. `Grep "list\.files\([^)]*\)\[1\]|\[grep\(" --glob "*.R"` for unchecked lookups. `Grep "download\.file\(" --glob "*.R"` against `Grep "options\(timeout" --glob "*.R"`.
- Local: run the driver twice in the same tree (the second run is the test). For a function `f`, `setdiff(names(formals(f)), all.names(body(f)))` lists the arguments its body never mentions; `Rscript <skill>/scripts/static_sweep.R <repo>` lists every function with its arguments so that sweep can be scripted.

**R specifics**
- `which(x > 0)` and `which(!(x > 0))` both drop NA, so a row with NA lands in neither subset; `%in%`, `is.na()` or `isTRUE()` keep it.
- `terra::writeRaster()` and `raster::writeRaster()` stop on an existing file unless `overwrite = TRUE`; `dir.create()` is non-recursive by default and only warns.
- `sample(x)` on a length-one numeric `x` samples `1:x`; `ifelse()` drops dates and attributes; `rbind()` of data frames matches columns by name but not by type.
- `try(..., silent = TRUE)` returns a `try-error` object that downstream code happily subsets.

**Evidence to record**: the quoted line and what happens (the error text from the second run, the count of rows dropped, the message that should have been a stop). A count goes in Doc C §3 with the command that produced it.

**Kind guidance**: an overwrite flag, a recursive `dir.create()`, a timeout or a `stop()` in place of a `message()` is mechanical. Fixing a filter that silently drops rows is behavioural, because the outputs differ, and needs a decision and a before/after table. A smoke failure from Phase 4 is recorded in this lens.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| B1 | EcospaceBasemap `R/dbSEABED_functions.R:290` | `terra::writeRaster(seabed.stack,filename=paste0(dir.out,"/",...))` without `overwrite=TRUE` (the writer at `:200-201` has it), so a second run in the same tree stops with "file exists" | mechanical | medium | open |
| B2 | EcospaceBasemap `R/artificial_reef_functions.R:174-175` | `withrel <- reef[which(reef$Relief > 0), ]` / `norel <- reef[which(!(reef$Relief > 0)), ]`: `which()` drops rows whose Relief is NA from both subsets, so records with missing relief never reach the fill written for them and vanish from the returned table | behavioural | medium | open |
| B3 | RedTideMaps `scripts/get_HAB_data.R:211` | `download.file(url = paste0(data_url, csv), destfile = dest, mode = "wb")` with R's 60 s default timeout, no `try()` and no `options(timeout)` anywhere under `scripts/`; a slow server ends the run mid-stage (EcospaceBasemap `R/dbSEABED_functions.R:58-59` shows the raise-and-restore pattern) | mechanical | low | open |
| B4 | GFISHER `R/maxn_maps.R:11` @3e4dea1 (plan doc `:75`) | `save.format='ascii'` accepted but read nowhere except its own comment (`:24`); always writes ASCII. Header default `fun='sum'` while the driver passes `fun=mean` (`process GFISHER data.R:107` @3e4dea1) | mechanical | low | fix: step 6 |

## D documentation

Asks: does the prose match the code? Feeds Doc A and Doc B throughout.

**What to look for**
- README or comments that describe a variable, file or layout that does not exist (renamed, moved, never written).
- Statements about where outputs land, what is tracked or what a default is that disagree with the driver.
- The same number given twice with two values (a run time, a record count, a size).
- Choices made at a call site with no comment, when the function's own documentation says the choice matters.
- Function documentation out of step with the signature: parameters documented but gone, or present but undocumented; examples that call functions that no longer exist.
- Folder-level READMEs that are placeholders.

**How to check**
- Cloud: `Grep "\x60[A-Za-z_.][A-Za-z0-9_.$]*\x60" --glob "*.md"` and `Grep "cfg\$[A-Za-z_.]+|dir\.[A-Za-z_.]+|file\.[A-Za-z_.]+" --glob "*.{md,R,gitignore}"` for named identifiers in prose and comments, then check each against the assignments the static sweep lists. `Grep "[0-9]+ ?(s|sec|min|minutes|hours?|MB|GB|records?|cells?)\b" --glob "*.md"` for numbers to reconcile. `Grep "TODO|FIXME|XXX|HACK|legacy|deprecated" --glob "*.R"`. For call-site choices, `Grep "<argument> *=" --glob "*.R"` for each argument whose documentation carries a warning.
- Local: `Rscript <skill>/scripts/static_sweep.R <repo>` gives the function and variable inventory to check the prose against; running the README's quick-start commands as written is the test of the quick start.

**R specifics**
- roxygen `@param` names against `names(formals(f))`; `\dontrun{}` examples that reference retired functions or absolute paths.
- A driver comment that quotes the "legacy" value of an argument documents a methods choice; copy it into Doc A §5 rather than losing it.

**Evidence to record**: the two texts side by side, each with `file:line` (the prose and the code it should match). No measurement.

**Kind guidance**: always mechanical when the fix is to the prose. When the prose is right and the code is wrong, the row belongs to the lens whose fix changes the code, with a cross-reference here.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| D1 | EcospaceBasemap `.gitignore:12-13` | Comment says outputs live outside the repo "(cfg$out_root in make_WFS_basemaps.R)"; no `cfg` object exists, the variable is `dir.basemaps` (`make_WFS_basemaps.R:42`) and its default is inside the repo | mechanical | low | open |
| D2 | EcospaceBasemap `README.md:688` | "Everything lands under `dir.basemaps`, outside the repository" while the driver default is `file.path(getwd(),'output',paste0(res,'min'))` (`make_WFS_basemaps.R:42`) and `README.md:113` itself gives `<repo>/output/<res>min` as the default | mechanical | low | open |
| D3 | EcospaceBasemap `make_WFS_basemaps.R:179` | `anchor.zero = 'both')` passed with no comment, while the function's roxygen (`R/GFISHER functions.R:310-314`) says the setting biases the fill downward inshore and exists to match the old maps; the call site should say the choice is deliberate (the methods question is M3) | mechanical | medium | open |
| D4 | RedTideMaps `scripts/README.md:1` | The whole file is "Create a folder"; nothing says what `scripts/`, `scripts/old scripts/` or `scripts/experimental/` hold | mechanical | low | open |
| D5 | RedTideMaps `README.md:83,112` | First run "about 20 minutes" at `:83` and "about 19 minutes" at `:112`; one measured figure should feed both | mechanical | low | open |

## M methods and statistics

Asks: what is being estimated, under what assumptions, and does the code do that? Feeds Doc A §5 and §7, Doc B §5.

**What to look for**
- Every model, estimator, interpolation and classification call: the formula, the family, the weights, the parameters, and whether they match what Doc A says is estimated.
- Fallbacks that fire on a failed fit and run a different method with different settings, silently.
- Units: a quantity published in one unit and used as another; constants that imply a conversion nobody documents.
- Thresholds, bins and pooling rules chosen by hand or by a heuristic, and whether the heuristic does what the comment says.
- Settings the driver passes that the function's own documentation warns about.
- Index values described as proportions when they are not bounded by 1.

**How to check**
- Cloud: `Grep "lm\(|glm\(|gam\(|kmeans\(|hclust\(|krige\(|variogram\(|idw\(|sdmTMB\(|mice\(|boot\(|optim\(|nls\(|family *=" --glob "*.R"` for the inventory; `Grep -i "fall(ing)? ?back" --glob "*.R"` and read what the fallback passes; `Grep -i "\b(ft|feet|m|metres|meters|km|deg|cells/L)\b" --glob "*.{R,md}"` on comments and column names, plus `Grep "0\.3048|3\.28|1e3\b|1e6\b" --glob "*.R"` for conversions; `Grep "breaks *=|cut\(|quantile\(|which\.max\(|>=? *[0-9]" --glob "*.R"` for thresholds and heuristics.
- Local: reproduce one number by hand for each estimator (one cell, one month, one species) from the inputs, and keep the script; it becomes an experiment script Doc C cites.

**R specifics**
- `kmeans()` with the default `nstart = 1` depends on the start; `cut()` with `include.lowest` and right-closed intervals puts boundary values where the comment may not expect; `quasibinomial` against `binomial` changes standard errors, not estimates.
- A recursive fallback call inside a function has to pass every argument the caller set; otherwise a `match.arg()` default silently takes over.

**Evidence to record**: the equation as implemented, the parameter values in force, and where possible one measured effect (a filled mean before and after, a count of months affected) in Doc C §3.

**Kind guidance**: mostly scientific: units, thresholds, pooling rules and parameter choices change what the method means, so the arithmetic stays as it is and the item goes to the author in Doc C §8 with the options laid out. A fallback that drops the caller's settings is behavioural (restoring them changes outputs only when the fallback fires) and needs a decision. Writing the choice down at the call site is a mechanical D fix.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| M1 | EcospaceBasemap `R/artificial_reef_functions.R:40-44,302-308` | FWC publishes Relief in feet ("Relief (ft)", `:40`) while `fn.make_AR_maps()` computes `sum(area_m2 * relief_m) / 1e6 / cell_area_km2` and quotes a median relief of "8 m" (`:305`); `README.md:500-501` repeats the metres formula. Left unchanged so outputs stay comparable with the legacy grids | scientific | high | author |
| M2 | EcospaceBasemap `R/GFISHER functions.R:184-188,260-264` | GAM and variogram failures both `return(fn.fill_habitat_gaps(r, ..., method = "idw", ...))` passing neither `anchor.zero`, `strata`/`strata.breaks` nor `clamp.to.observed`, so a failed fit runs IDW with `anchor.zero = "none"` and clamping on, whatever the caller asked | behavioural | medium | open |
| M3 | EcospaceBasemap `make_WFS_basemaps.R:179` with `R/GFISHER functions.R:40-47` | `anchor.zero = 'both'` adds synthetic zeros on land and past `max.depth`; the roxygen measures the effect ("NL filled mean 0.0118 -> 0.0049 at 5 min") and keeps it to match the old maps. Whether to keep it is the author's call (the call-site comment is D3) | scientific | medium | author |
| M4 | RedTideMaps `docs/issue3-hull-fix-plan.md:37-39` (pre-fix `scripts/polygon_clipping_rt.R:65`) | Elbow rule `which.max(abs(diff(wss))) + 1` always picks k = 2 (15 of 15 months in the emulation), so distinct bloom regions merge into one elongated hull; replaced by single linkage cut at `hull_link_km` | scientific | high | fix: step 3 (decision 1) |

## S stochasticity

Asks: where is randomness, is it seeded, and does the seed live where it should? Feeds Doc B §6.

**What to look for**
- Every random draw: sampling, jitter, random starts of a clustering or optimiser, bootstraps, imputation, random initial values in a fit.
- Draws with no seed, so outputs differ run to run.
- Seeds in the wrong place: at file scope (runs once when the file is sourced, not when the function runs), inside a function (mutates the global RNG as a side effect), or fixed with no way to override.
- Parallel code that seeds its workers differently each time.
- The seed's reach: which outputs depend on it and which do not, so the same-seed and cross-seed tests have invariants to check.

**How to check**
- Cloud: `Grep "set\.seed\(|sample\(|sample\.int\(|runif\(|rnorm\(|rtruncnorm\(|rbinom\(|rpois\(|jitter\(|kmeans\(|nstart|mice\(|boot\(|RNGkind\(|\.Random\.seed|mclapply\(|future" --glob "*.R"`; for each hit, find the nearest `set.seed()` above it in the call chain and note its scope.
- Local: run the driver twice with the same seed and `Rscript <skill>/scripts/snapshot_md5.R compare run1.csv run2.csv --md` (identical, or the list of what moved); then with a different seed, to learn which outputs the seed reaches. `<skill>/references/verification.md` holds the same-seed and cross-seed protocol.

**R specifics**
- `set.seed()` inside a function resets the session's RNG for everything after it; save `.Random.seed` on entry and restore it on exit, or seed once in the driver.
- `kmeans()` draws its starts from the RNG, so an unseeded `kmeans()` is a random method; `sample()` changed algorithm in R 3.6.0 (`sample.kind`), so seeds from older sessions do not reproduce.
- `set.seed()` at the top of a function file runs at `source()` time and is defeated by any draw between sourcing and fitting.

**Evidence to record**: the draw and the nearest seed, both with locations; the same-seed comparison (identical, or which files moved) and the cross-seed table (which outputs changed, which were invariant) in Doc B §6, cited from Doc C §3.

**Kind guidance**: adding a seed where there was none is behavioural: the outputs change once and need a decision and a before/after table. Moving an existing seed is mechanical only when the same-seed test shows identical outputs. Replacing a random method with a deterministic one is scientific and goes to the author unless they decide it in the issue.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| S1 | GFISHER `R/video_dataset.R:161-169` @3e4dea1 (plan doc `:62`) | `len.i = round(rtruncnorm(nrow(dat.i),...))` and `obslen.i[sample.int(nrow(dat.i))]` with no `set.seed`; the baseline run changed 11 of 19 MaxN rasters (plan doc §4.1) | behavioural | high | fix: step 4 |
| S2 | EcospaceBasemap `R/artificial_reef_functions.R:262` | `set.seed(seed)` inside `fn.classify_ar_relief()` resets the global RNG on every call; `kmeans()` at `:263` is the only draw in the repository today, so nothing downstream moves yet, but any later random step in the same session inherits seed 42 | mechanical | low | open |
| S3 | RedTideMaps `scripts/sdmTMB_HAB_data.R:14` | `set.seed(6)` at file scope runs once at `source()` time, not when the fit functions run, so the RNG state at fit time depends on what was sourced and drawn in between | behavioural | medium | open |
| S4 | RedTideMaps `docs/issue3-hull-fix-plan.md:44` (pre-fix hull code) | "`kmeans()` is unseeded, so hull polygons (and therefore ASCII deliverables for fallback months) are not reproducible run to run. The jitter on line 48 (`runif`) is unseeded too." Resolved by the deterministic single-linkage rule (`scripts/polygon_clipping_rt.R:95`) | behavioural | high | fix: step 3 |

## T run time

Asks: where does the time go, and what could be cached or skipped? Feeds Doc B §8.

**What to look for**
- Which stage dominates, from the log, not from memory.
- Work redone on every run that could be cached: a large read, a fit per month, a download.
- Skip toggles and incremental caches that exist, how they are invalidated, and whether the README says so.
- Timing claims in prose and comments with no measurement behind them.
- Repeated reads of the same large input inside a loop.

**How to check**
- Cloud: `Grep "[0-9]+ ?(s|sec|min|minutes|hours?)\b" --glob "*.{R,md}"` for claims; `Grep -i "incremental|cache|skip|already (exist|present)|overwrite *= *FALSE" --glob "*.R"` for existing caches and toggles; `Grep "Sys\.time\(\)|system\.time\(|proc\.time\(|tictoc" --glob "*.R"` for existing timers; `Grep "st_read\(|read_sf\(|rast\(|raster\(|read\.csv\(" --glob "*.R"` inside `for` and `lapply` bodies for repeated reads.
- Local: `Rscript <skill>/scripts/run_logged.R <driver.R> --out <dir>` gives the wall time and a timestamped log; stage durations are the differences between consecutive stage lines. Record them in the Doc B §8 table (stage | wall time | what dominates | cache or skip candidate), saying what else was running and whether caches were warm.

**R specifics**
- A log function that stamps each line is enough to derive stage times; RedTideMaps `rt_log()` (`scripts/_setup.R:150-155`: `paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", msg)` to console and file, called at every step of `run_redtide_maps.R`) is the pattern to copy where there is none.
- A cache keyed on the output path with a documented way to invalidate it is the pattern for skips: RedTideMaps `run_redtide_maps.R:75`, `incremental_fit = TRUE, # skip months already fit (delete OM_month/<yyyymm>/ to force refit)`, with its measured effect in `README.md:112-117` (rerun 8 min 50 s with 0 months to refit; `incremental_fit = FALSE` adds about 6 min).
- Geodatabase and shapefile reads through `sf` dominate most pipelines of this kind; an `.rds` of the read, invalidated when the source is newer, is the usual first cache.

**Evidence to record**: the measured stage table with machine, date, warm or cold cache, and where the number came from (log or wall clock); a claim with no measurement is recorded as "claimed, not measured".

**Kind guidance**: a cache or skip is mechanical only when the outputs are byte-identical with and without it (prove it with `snapshot_md5.R compare`); a skip that changes which months or cells are recomputed when new data arrive is behavioural and needs a decision. Writing a measured time into the README is a mechanical D fix.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| T1 | GFISHER `CLAUDE.md:16` with plan doc `:107` | "A full run is about 16 minutes; stage 1's geodatabase read dominates"; the baseline measured exit code 0, wall time 15 min 39 s; the geodatabase read (309,348 microgrids) is the cache candidate | mechanical | low | open |
| T2 | EcospaceBasemap `make_WFS_basemaps.R:189-190` | Comment claims "Slow (~2 min at 5 min resolution) - the fuzzy joins dominate"; no timer, log or `Sys.time()` exists in the repository (`Grep "Sys\.time\|proc\.time\|system\.time" --glob "*.R"` finds only a provenance stamp at `R/data_setup_functions.R:433`), so no stage time can be derived; claimed, not measured | mechanical | low | open |
| T3 | RedTideMaps `README.md:84,86` | First-run stage times "(~3 min, ~216k records)" for the pull and "(~7 min)" for the fits are stated with no log in the repository (run logs are gitignored, `.gitignore:14-15`); Doc B §8 takes them from a fresh `run_logged.R` run, not from the README | mechanical | low | open |

## E efficiency and artifacts

Asks: what is unused, duplicated or left behind? Feeds Doc B §8.

**What to look for**
- Functions defined and never called; files never sourced by the driver or by anything it sources.
- The same helper defined twice, identically or (worse) slightly differently.
- Scratch, "old", backup and experimental folders with no README saying what they are and whether they still run.
- Tracked files no code reads: documents, slides, email exports, spreadsheets, large binaries.
- Output folders no current code writes; tracked files that `.gitignore` matches.
- Long commented-out blocks of code.

**How to check**
- Cloud: `Grep "^[A-Za-z_.][A-Za-z0-9_.]* *(<-|=) *function" --glob "*.R"` for the definitions, then `Grep "\bfn_name\(" --glob "*.R"` for each name to find its callers (the definition and any roxygen example count as none); a name that appears twice in the first list is a duplicate. `git ls-files | grep -iE 'old|scratch|tmp|temp|backup|bak|copy|_v[0-9]|experimental'` for leftover folders; `git ls-files | grep -iE '\.(pdf|pptx|docx|msg|xlsx|zip|RData|rds)$'` for tracked artifacts, then Grep each basename in `*.R` and `*.md`.
- Local: `Rscript <skill>/scripts/static_sweep.R <repo> --out <dir>` writes the function inventory, the never-called list and the never-sourced list; `git ls-files -z | xargs -0 du -b | sort -n | tail -20` for the largest tracked files; `git ls-files -ci --exclude-standard` for tracked-but-ignored.

**R specifics**
- A roxygen `\dontrun{}` example that calls the function is not a caller; neither is a commented-out line.
- `source()` over `list.files("R")` loads every file in the folder, so a dead function there is still defined and can mask a live one of the same name.
- `.Rhistory`, `.RData`, `Rplots.pdf` and `.Rproj.user/` are session cruft; they belong in `.gitignore`, not the index.

**Evidence to record**: the definition line and the result of the caller search ("no caller; the only other mention is the roxygen example at :126"); for tracked artifacts, the file list with sizes from `du -b` and the empty result of the reader search.

**Kind guidance**: moves to `hoard/` or `archive/` and `git rm --cached` are mechanical findings, closed by `housekeeping` commits that list every file; nothing is deleted. Removing a duplicate definition is mechanical when the two bodies are identical and behavioural when they differ, because the surviving one may not be the one that ran.

**Real examples**

| ID | Where (file:line) | Problem | Kind | Severity | Status |
|---|---|---|---|---|---|
| E1 | EcospaceBasemap `R/dbSEABED_functions.R:135` | `fn.make_dbseabed_ascii <- function(dir.dbseabed, dir.ascii, depth, resample.method='near')` has no caller; the only other mention is its own `\dontrun` example at `:126`; superseded by the normalised writer at `:199-201` | mechanical | low | open |
| E2 | EcospaceBasemap `R/artificial_reef_functions.R:172,212` | `strip <- function(x) tolower(gsub("[^[:alnum:]]", "", x))` defined identically inside `fn.fill_reef_relief()` and `fn.match_ar_relief()`; one file-level helper would do | mechanical | low | open |
| E3 | GFISHER `refs/` | Five tracked files, 12.6 MB (`du -b`): two PDFs, one PPTX and two Outlook `.msg` exports; `Grep "refs/" --glob "*.{R,md}"` finds no reader | mechanical | low | open |
| E4 | RedTideMaps `scripts/old scripts/` | Ten superseded scripts (`1_extract MODIS v2.R` to `VAST_redtide_DC2.R`), no README, other users' paths (`polygon_clipping_rt.R:19-25`); `Grep "old scripts" --glob "*.{R,md}"` finds nothing that sources them | mechanical | low | open |
| E5 | GFISHER `output/affinity_selratio/` @3e4dea1 (plan doc `:65`) | Untagged output folder that no current code writes (current code writes `affinity_selratio_<scheme>/`); the baseline left its five files untouched (plan doc §4.1) | mechanical | low | fix: step 9 (decision 8) |

## Cross-lens rules

- Every row has `file:line` against the commit named in Doc C §0 and either a quoted snippet or a measurement; a row with neither is a note, not a finding, and does not enter the register.
- A finding discovered later (by the baseline run, by a fresh-clone test, by the author's reply) is appended to its lens table with its origin in the Problem cell ("Found by the baseline run", "Found by the fresh-clone test on 2 Oct 2026"), never left in prose only; GFISHER R5 and R6 are the pattern.
- When a cause turns out to be wrong, correct it in the row, dated ("Cause settled 2 Oct 2026: an older template, not a package-version effect"), and keep the first reading beside it, because the next reader will have the same first idea.
- One problem gets one ID. Choose the lens by the fix that resolves it, and put a cross-reference in the Problem cell when another lens applies: caching a live download is one R row that also saves the download time, not an R row and a T row. Split only when the fixes differ in kind: EcospaceBasemap's `anchor.zero = 'both'` is a mechanical D row (write the choice down at the call site) and a scientific M row (whether to keep it), because one is done now and the other goes to the author.
- A documentation-only fix is mechanical whatever lens the row sits in; a behavioural row carries a decision number in its Status; a scientific row ends as `author` with a Doc C §8 entry, and the arithmetic stays as it is.
- Lens letter B is the bugs lens; the documents are always written "Doc A", "Doc B", "Doc C" (for example "Doc B §9") so the two never read as one.
- Commits that close rows have a type (`code`, `docs`, `outputs`, `housekeeping`, `record`), named in Doc C §6 beside the IDs closed, so `git log --grep=<ID>` finds the commit.
- Pre-ready check (Phase 9): no row still `open`; no placeholder ("to be added", "pending") anywhere in Doc C; every unticked §5 step carried to a sub-issue; every changed output explained in Doc B §9; Doc C §11 lists an outcome for every ID.
