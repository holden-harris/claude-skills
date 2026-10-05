# static_sweep.R ----------------------------------------------------------------------------
# Purpose: parse-only inventory of an R repository for the code-audit skill. Nothing is
#   executed; files are only parsed and read. Reports: parse failures (the Phase 4 smoke
#   check), function definitions with call counts and roxygen coverage, files never sourced,
#   and pattern hits by category (machine paths, setwd, workspace wipes, platform-only calls,
#   random draws and seeds, download timeouts, writeRaster without overwrite, <<-, TODO).
# Usage: Rscript static_sweep.R <repo> [--out <dir>] [--exclude "<regex>"]
#   --out      folder for the CSVs (default: <repo>/../<basename(repo)>-audit/sweep/)
#   --exclude  regex of paths to skip (default: (^|/)(archive|hoard|old scripts|renv|\.git)(/|$))
# Outputs: sweep_functions.csv, sweep_files.csv, sweep_patterns.csv in --out, and a markdown
#   summary on the console (paste it into Doc C section 3 or Doc B section 8).
# Limits: call counts come from parse tokens, so a function passed by name (sapply(x, f)) or
#   called through do.call() is not counted; files sourced through a loop over list.files()
#   show as "dynamic" rather than by name. Treat zero-call and never-sourced lists as leads.
# Base R only. Untested in the authoring session (no R available); the first local run is the
# acceptance test. Report problems in the skill's issue tracker.

args <- commandArgs(trailingOnly = TRUE)
usage <- function(msg = NULL) {
  if (!is.null(msg)) cat("static_sweep.R:", msg, "\n")
  cat("Usage: Rscript static_sweep.R <repo> [--out <dir>] [--exclude \"<regex>\"]\n")
  quit(status = 2)
}
if (length(args) < 1) usage()
repo <- NULL; out <- NULL
exclude <- "(^|/)(archive|hoard|old scripts|renv|\\.git)(/|$)"
i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (a == "--out") {
    if (i == length(args)) usage("--out needs a folder")
    out <- args[i + 1]; i <- i + 2
  } else if (a == "--exclude") {
    if (i == length(args)) usage("--exclude needs a regex")
    exclude <- args[i + 1]; i <- i + 2
  } else if (is.null(repo)) {
    repo <- a; i <- i + 1
  } else {
    usage(paste("unexpected argument", a))
  }
}
if (is.null(repo)) usage("repository path missing")
if (!dir.exists(repo)) stop("Repository folder not found: ", repo, call. = FALSE)
repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)
if (is.null(out)) out <- file.path(dirname(repo), paste0(basename(repo), "-audit"), "sweep")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)

# Files --------------------------------------------------------------------------------------
files <- list.files(repo, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
rel <- substring(normalizePath(files, winslash = "/"), nchar(repo) + 2)
keep <- !grepl(exclude, rel)
files <- files[keep]; rel <- rel[keep]
if (length(files) == 0) stop("No .R files found under ", repo, call. = FALSE)

# Pattern categories (regex on non-comment source lines) ----------------------------------
patterns <- list(
  machine_path   = "\\b[A-Za-z]:/|/Users/|/home/|OneDrive|AppData",
  setwd          = "\\bsetwd\\(",
  workspace_wipe = "rm\\(list\\s*=\\s*ls\\(\\)",
  platform_only  = "\\bwindows\\(|\\bdev\\.new\\(|\\bchoose\\.dir\\(|\\bfile\\.choose\\(",
  rng_call       = "\\b(sample|sample\\.int|runif|rnorm|rbinom|rpois|rlnorm|rgamma|rbeta|kmeans|jitter|rtruncnorm)\\(",
  set_seed       = "\\bset\\.seed\\(",
  download       = "\\bdownload\\.file\\(",
  write_raster   = "\\bwriteRaster\\(",
  superassign    = "<<-",
  todo           = "\\b(TODO|FIXME|XXX)\\b|\\bbrowser\\(",
  timing_or_env  = "\\bsessionInfo\\(|\\bSys\\.time\\(|\\bproc\\.time\\(|\\btictoc\\b"
)

# Helpers ------------------------------------------------------------------------------------
is_comment_line <- function(x) grepl("^\\s*#", x)
has_roxygen_above <- function(src, line) {
  j <- line - 1
  while (j >= 1 && !nzchar(trimws(src[j]))) j <- j - 1
  j >= 1 && grepl("^\\s*#'", src[j])
}
# TRUE when the parse-data node `id` sits inside a function body.
inside_function <- function(pd, id) {
  pmap <- stats::setNames(pd$parent, as.character(pd$id))
  cur <- unname(pmap[as.character(id)])
  while (length(cur) == 1 && !is.na(cur) && cur > 0) {
    if ("FUNCTION" %in% pd$token[pd$parent == cur]) return(TRUE)
    cur <- unname(pmap[as.character(cur)])
  }
  FALSE
}

# Per-file analysis --------------------------------------------------------------------------
parse_failures <- data.frame(file = character(0), message = character(0), stringsAsFactors = FALSE)
fun_rows <- list(); file_rows <- list(); pat_rows <- list()
calls_all <- data.frame(name = character(0), file = character(0), stringsAsFactors = FALSE)

for (k in seq_along(files)) {
  f <- files[k]; r <- rel[k]
  src <- readLines(f, warn = FALSE)
  pd <- tryCatch({
    ex <- parse(text = src, keep.source = TRUE)
    utils::getParseData(ex, includeText = FALSE)
  }, error = function(e) e)
  if (inherits(pd, "error")) {
    parse_failures <- rbind(parse_failures,
                            data.frame(file = r, message = conditionMessage(pd), stringsAsFactors = FALSE))
    pd <- NULL
  }

  # Function definitions: expr(SYMBOL) <- or = expr(FUNCTION ...)
  defs <- data.frame(name = character(0), line = integer(0), top_level = logical(0), stringsAsFactors = FALSE)
  n_top_level_other <- NA_integer_
  if (!is.null(pd) && nrow(pd) > 0) {
    fun_tokens <- pd[pd$token == "FUNCTION", , drop = FALSE]
    for (t in seq_len(nrow(fun_tokens))) {
      fexpr <- fun_tokens$parent[t]
      aexpr <- pd$parent[pd$id == fexpr]
      if (length(aexpr) != 1 || is.na(aexpr) || aexpr <= 0) next
      kids <- pd[pd$parent == aexpr, , drop = FALSE]
      kids <- kids[order(kids$line1, kids$col1), , drop = FALSE]
      if (nrow(kids) < 3) next
      if (!(kids$token[2] %in% c("LEFT_ASSIGN", "EQ_ASSIGN")) || kids$id[3] != fexpr) next
      lhs <- pd[pd$parent == kids$id[1] & pd$token == "SYMBOL", , drop = FALSE]
      if (nrow(lhs) == 0) next
      top <- pd$parent[pd$id == aexpr]
      defs <- rbind(defs, data.frame(name = lhs$text[1], line = kids$line1[1],
                                     top_level = (length(top) == 1 && top == 0),
                                     stringsAsFactors = FALSE))
    }
    roots <- pd[pd$parent == 0 & pd$token == "expr", , drop = FALSE]
    n_top_level_other <- nrow(roots) - sum(defs$top_level)
    # Call sites
    calls <- pd[pd$token == "SYMBOL_FUNCTION_CALL", , drop = FALSE]
    if (nrow(calls) > 0)
      calls_all <- rbind(calls_all, data.frame(name = calls$text, file = r, stringsAsFactors = FALSE))
  }
  if (nrow(defs) > 0) {
    defs$file <- r
    defs$has_roxygen <- vapply(defs$line, function(l) has_roxygen_above(src, l), logical(1))
    fun_rows[[length(fun_rows) + 1]] <- defs
  }

  # library()/require() and source() targets, from source lines
  lib_lines <- grep("\\b(library|require|requireNamespace)\\(", src, value = TRUE)
  lib_lines <- lib_lines[!is_comment_line(lib_lines)]
  libs <- unique(gsub("^.*\\b(library|require|requireNamespace)\\(\\s*['\"]?([A-Za-z0-9.]+)['\"]?.*$", "\\2", lib_lines))
  libs <- libs[grepl("^[A-Za-z0-9.]+$", libs)]
  src_lines <- which(grepl("\\bsource\\(", src) & !is_comment_line(src))
  src_targets <- character(0); dynamic_source <- FALSE
  for (l in src_lines) {
    m <- regmatches(src[l], regexpr("source\\(\\s*['\"]([^'\"]+)['\"]", src[l]))
    if (length(m) == 1) src_targets <- c(src_targets, sub("^source\\(\\s*['\"]", "", sub("['\"]$", "", m)))
    else dynamic_source <- TRUE
  }
  file_rows[[length(file_rows) + 1]] <- data.frame(
    file = r, parsed = is.null(pd) == FALSE, n_lines = length(src),
    functions_defined = if (nrow(defs) > 0) paste(defs$name, collapse = ";") else "",
    n_functions = nrow(defs), top_level_expressions = n_top_level_other,
    library_calls = paste(libs, collapse = ";"),
    source_targets = paste(src_targets, collapse = ";"),
    dynamic_source = dynamic_source, stringsAsFactors = FALSE)

  # Pattern hits on non-comment lines
  seed_seen_line <- NA_integer_
  for (l in seq_along(src)) {
    line <- src[l]
    if (is_comment_line(line) || !nzchar(trimws(line))) next
    for (cat_name in names(patterns)) {
      if (!grepl(patterns[[cat_name]], line, perl = TRUE)) next
      if (cat_name == "machine_path" && grepl("https?://", line)) next
      note <- ""
      if (cat_name == "set_seed") {
        if (is.na(seed_seen_line)) seed_seen_line <- l
        if (!is.null(pd)) {
          tok <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text == "set.seed" & pd$line1 == l, , drop = FALSE]
          if (nrow(tok) > 0) note <- if (inside_function(pd, tok$id[1])) "inside a function (resets the session's random state as a side effect)" else "file-scope seed (runs whenever the file is sourced)"
        }
      }
      if (cat_name == "rng_call")
        note <- if (!is.na(seed_seen_line) && seed_seen_line < l) paste0("set.seed() seen earlier at line ", seed_seen_line) else "no set.seed() earlier in this file"
      if (cat_name == "download")
        note <- if (any(grepl("timeout", src))) "a timeout appears in this file" else "no timeout raised in this file (R's default is 60 s)"
      if (cat_name == "write_raster")
        note <- if (grepl("overwrite", line)) "overwrite set on this line" else "no overwrite on this line (a second run may fail)"
      pat_rows[[length(pat_rows) + 1]] <- data.frame(category = cat_name, file = r, line = l,
                                                     text = trimws(line), note = note, stringsAsFactors = FALSE)
    }
  }
}

functions <- if (length(fun_rows)) do.call(rbind, fun_rows) else
  data.frame(name = character(0), line = integer(0), top_level = logical(0), file = character(0), has_roxygen = logical(0))
files_df <- do.call(rbind, file_rows)
pats <- if (length(pat_rows)) do.call(rbind, pat_rows) else
  data.frame(category = character(0), file = character(0), line = integer(0), text = character(0), note = character(0))

# Call counts per defined function (across all files)
if (nrow(functions) > 0) {
  functions$n_calls <- vapply(functions$name, function(n) sum(calls_all$name == n), integer(1))
  functions$called_from <- vapply(functions$name, function(n) paste(unique(calls_all$file[calls_all$name == n]), collapse = ";"), character(1))
}
# sourced_by: files whose literal source() targets end with this file's name
files_df$sourced_by <- vapply(files_df$file, function(r) {
  hits <- files_df$file[vapply(strsplit(files_df$source_targets, ";", fixed = TRUE), function(tg) any(nzchar(tg) & endsWith(r, sub("^\\./", "", tg))), logical(1))]
  paste(setdiff(hits, r), collapse = ";")
}, character(1))

# Write CSVs ---------------------------------------------------------------------------------
utils::write.csv(functions, file.path(out, "sweep_functions.csv"), row.names = FALSE)
utils::write.csv(files_df, file.path(out, "sweep_files.csv"), row.names = FALSE)
utils::write.csv(pats, file.path(out, "sweep_patterns.csv"), row.names = FALSE)

# Markdown summary ---------------------------------------------------------------------------
md <- c(paste0("# Static sweep of ", basename(repo)),
        paste0("Files parsed: ", sum(files_df$parsed), " of ", nrow(files_df), " (", nrow(files_df), " .R files after excluding `", exclude, "`)."),
        paste0("CSVs: ", out), "",
        "## Parse failures")
md <- c(md, if (nrow(parse_failures) == 0) "None." else paste0("- `", parse_failures$file, "`: ", parse_failures$message))
dup <- if (nrow(functions) > 0) functions$name[duplicated(functions$name) | duplicated(functions$name, fromLast = TRUE)] else character(0)
md <- c(md, "", "## Functions defined more than once")
md <- c(md, if (length(dup) == 0) "None." else vapply(unique(dup), function(n) {
  rows <- functions[functions$name == n, ]
  paste0("- `", n, "`: ", paste0(rows$file, ":", rows$line, collapse = ", "))
}, character(1)))
md <- c(md, "", "## Functions with zero call sites (leads, not verdicts)")
zero <- if (nrow(functions) > 0) functions[functions$n_calls == 0, ] else functions
md <- c(md, if (nrow(zero) == 0) "None." else paste0("- `", zero$name, "` (", zero$file, ":", zero$line, ")"))
md <- c(md, "", "## Candidate dead files (never sourced by name, no top-level expressions)")
dead <- files_df[!nzchar(files_df$sourced_by) & !is.na(files_df$top_level_expressions) & files_df$top_level_expressions == 0, ]
md <- c(md, if (nrow(dead) == 0) "None." else paste0("- `", dead$file, "`"))
if (any(files_df$dynamic_source)) md <- c(md, paste0("Files with dynamic source() calls (their targets are not resolved here): ", paste(files_df$file[files_df$dynamic_source], collapse = ", ")))
md <- c(md, "", "## Functions without a roxygen header")
norox <- if (nrow(functions) > 0) functions[!functions$has_roxygen, ] else functions
md <- c(md, if (nrow(norox) == 0) "None." else paste0("- `", norox$name, "` (", norox$file, ":", norox$line, ")"))
md <- c(md, "", "## Pattern hits by category", "", "| Category | Hits | First hits |", "|---|---|---|")
for (cat_name in names(patterns)) {
  sub <- pats[pats$category == cat_name, ]
  first <- if (nrow(sub) == 0) "" else paste0(utils::head(paste0(sub$file, ":", sub$line), 3), collapse = "; ")
  md <- c(md, paste0("| ", cat_name, " | ", nrow(sub), " | ", first, " |"))
}
md <- c(md, "", "Notes column in sweep_patterns.csv says, per hit, whether a seed precedes a random call, whether a download has a timeout, and whether writeRaster sets overwrite.")
cat(paste(md, collapse = "\n"), "\n")
