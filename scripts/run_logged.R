# run_logged.R ------------------------------------------------------------------------------
# Purpose: run an R driver script under a child Rscript with its full console output captured
#   to a log, preceded by an environment header (R version, OS, locale, git HEAD) and followed
#   by the exit status and wall time. The log lands outside the repository by default, so it
#   can never be committed by accident. Used for the Phase 4 baseline and the Phase 8 runs.
# Usage: Rscript run_logged.R <driver.R> [--out <dir>] [--cwd <repo>]
#   --cwd  working directory for the child (default: the folder containing the driver)
#   --out  folder for the log (default: <cwd>/../<basename(cwd)>-audit/<YYYYmmdd-HHMMSS>/)
# Output: <out>/run_<stamp>.log; the console shows the exit status, wall time and log path.
#   Live output accumulates in <out>/child_<stamp>.tmp until the child exits and is then merged
#   into the log. The child's stdout is block-buffered while stderr is not, so messages and
#   warnings can appear in the log before the printed output they relate to.
# Exit status: the child's exit status, so a failed run fails this script too.
# Base R only; the single system2() call starts the child Rscript. No shell pipes.
# Untested in the authoring session (no R available); the first local run is the acceptance
# test. Report problems in the skill's issue tracker.

args <- commandArgs(trailingOnly = TRUE)
usage <- function(msg = NULL) {
  if (!is.null(msg)) cat("run_logged.R:", msg, "\n")
  cat("Usage: Rscript run_logged.R <driver.R> [--out <dir>] [--cwd <repo>]\n")
  quit(status = 2)
}
if (length(args) < 1) usage()
driver <- NULL; out <- NULL; cwd <- NULL
i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (a == "--out") {
    if (i == length(args)) usage("--out needs a folder")
    out <- args[i + 1]; i <- i + 2
  } else if (a == "--cwd") {
    if (i == length(args)) usage("--cwd needs a folder")
    cwd <- args[i + 1]; i <- i + 2
  } else if (is.null(driver)) {
    driver <- a; i <- i + 1
  } else {
    usage(paste("unexpected argument", a))
  }
}
if (is.null(driver)) usage("driver path missing")
if (!file.exists(driver)) stop("Driver not found: ", driver, call. = FALSE)
driver <- normalizePath(driver, winslash = "/", mustWork = TRUE)
if (is.null(cwd)) cwd <- dirname(driver)
if (!dir.exists(cwd)) stop("Working directory not found: ", cwd, call. = FALSE)
cwd <- normalizePath(cwd, winslash = "/", mustWork = TRUE)
stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
if (is.null(out)) out <- file.path(dirname(cwd), paste0(basename(cwd), "-audit"), stamp)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)
logfile <- file.path(out, paste0("run_", stamp, ".log"))
child_log <- file.path(out, paste0("child_", stamp, ".tmp"))

# git HEAD without calling git: read .git/HEAD and the ref it points to (or packed-refs).
git_head <- function(dir) {
  gitdir <- file.path(dir, ".git")
  if (file.exists(gitdir) && !dir.exists(gitdir)) {   # a worktree or submodule: .git is a file "gitdir: <path>"
    gd <- sub("^gitdir:\\s*", "", readLines(gitdir, warn = FALSE, n = 1))
    gitdir <- if (grepl("^(/|[A-Za-z]:)", gd)) gd else file.path(dir, gd)
  }
  head_file <- file.path(gitdir, "HEAD")
  if (!file.exists(head_file)) return("not a git repository (no .git/HEAD in the working directory)")
  head <- readLines(head_file, warn = FALSE, n = 1)
  if (length(head) == 0 || !nzchar(head)) return("unknown (empty .git/HEAD)")
  if (!grepl("^ref: ", head)) return(paste(head, "(detached)"))
  ref <- sub("^ref: ", "", head)
  ref_file <- file.path(gitdir, ref)
  sha <- "unknown"
  if (file.exists(ref_file)) {
    sha <- readLines(ref_file, warn = FALSE, n = 1)
  } else {
    packed <- file.path(gitdir, "packed-refs")
    if (file.exists(packed)) {
      lines <- readLines(packed, warn = FALSE)
      hits <- lines[endsWith(lines, paste0(" ", ref))]
      if (length(hits) > 0) sha <- sub(" .*$", "", hits[1])
    }
  }
  paste0(sha, " (", ref, ")")
}

info <- Sys.info()
start <- Sys.time()
header <- c(
  "==== run_logged.R ====",
  paste0("Driver:        ", driver),
  paste0("Working dir:   ", cwd),
  paste0("Git HEAD:      ", git_head(cwd)),
  paste0("R:             ", R.version.string, " on ", R.version$platform),
  paste0("OS:            ", paste(info[c("sysname", "release", "machine")], collapse = " ")),
  paste0("Locale:        ", Sys.getlocale("LC_COLLATE")),
  paste0("Started:       ", format(start, "%Y-%m-%d %H:%M:%S %Z")),
  paste0("Log:           ", logfile),
  "==== driver output follows ===="
)
writeLines(header, logfile)
cat(paste(header, collapse = "\n"), "\n")

rscript <- file.path(R.home("bin"), "Rscript")
old_wd <- setwd(cwd)
status <- system2(rscript, args = shQuote(driver), stdout = child_log, stderr = child_log, wait = TRUE)
end <- Sys.time()
elapsed <- difftime(end, start, units = "secs")
child <- if (file.exists(child_log)) readLines(child_log, warn = FALSE) else character(0)
footer <- c(
  "==== end of driver output ====",
  paste0("Exit status:   ", status),
  paste0("Finished:      ", format(end, "%Y-%m-%d %H:%M:%S %Z")),
  paste0("Wall time:     ", sprintf("%.1f s (%.1f min)", as.numeric(elapsed), as.numeric(elapsed) / 60))
)
cat(child, file = logfile, sep = "\n", append = TRUE)
cat(footer, file = logfile, sep = "\n", append = TRUE)
unlink(child_log)
cat(paste(footer, collapse = "\n"), "\n")
quit(status = if (is.na(status)) 1L else as.integer(status))
