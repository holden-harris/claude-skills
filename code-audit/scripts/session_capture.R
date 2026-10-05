# session_capture.R -------------------------------------------------------------------------
# Purpose: print (and optionally write) a markdown table describing the R environment: R
#   version, platform, OS, locale, date, and the version of each package of interest. Used for
#   the environment line of Doc B section 9 and for the cloud hand-off.
# Usage:
#   Rscript session_capture.R [pkg ...] [--out <file.md>] [--from <sweep_files.csv>]
#     pkg ...          package names to report (packageVersion() or "not installed")
#     --from <csv>     read package names from the library_calls column of a sweep_files.csv
#                      written by static_sweep.R (semicolon-separated values)
#     with neither, the packages attached by default in this session are reported
# Also prints .libPaths(), whether renv is active, and whether renv.lock exists here.
# Base R only. Untested in the authoring session (no R available); the first local run is the
# acceptance test. Report problems in the skill's issue tracker.

args <- commandArgs(trailingOnly = TRUE)
usage <- function(msg = NULL) {
  if (!is.null(msg)) cat("session_capture.R:", msg, "\n")
  cat("Usage: Rscript session_capture.R [pkg ...] [--out <file.md>] [--from <sweep_files.csv>]\n")
  quit(status = 2)
}
pkgs <- character(0); out <- NULL; from <- NULL
i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (a == "--out") {
    if (i == length(args)) usage("--out needs a file name")
    out <- args[i + 1]; i <- i + 2
  } else if (a == "--from") {
    if (i == length(args)) usage("--from needs a csv path")
    from <- args[i + 1]; i <- i + 2
  } else if (grepl("^--", a)) {
    usage(paste("unknown option", a))
  } else {
    pkgs <- c(pkgs, a); i <- i + 1
  }
}
if (!is.null(from)) {
  if (!file.exists(from)) stop("--from file not found: ", from, call. = FALSE)
  sw <- utils::read.csv(from, stringsAsFactors = FALSE)
  if (!"library_calls" %in% names(sw)) stop("--from file has no library_calls column", call. = FALSE)
  extra <- unlist(strsplit(sw$library_calls[!is.na(sw$library_calls)], ";", fixed = TRUE))
  pkgs <- c(pkgs, trimws(extra))
}
if (length(pkgs) == 0) {
  pkgs <- sub("^package:", "", grep("^package:", search(), value = TRUE))
}
pkgs <- unique(pkgs[nzchar(pkgs)])

pkg_version <- function(p) {
  tryCatch(as.character(utils::packageVersion(p)), error = function(e) "not installed")
}
info <- Sys.info()
lines <- c(
  "| Item | Value |",
  "|---|---|",
  paste0("| R version | ", R.version.string, " |"),
  paste0("| Platform | ", R.version$platform, " |"),
  paste0("| OS | ", paste(info[c("sysname", "release")], collapse = " "), " |"),
  paste0("| Machine | ", info[["machine"]], " |"),
  paste0("| Locale | ", Sys.getlocale("LC_COLLATE"), " |"),
  paste0("| Date | ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), " |"),
  paste0("| Library paths | ", paste(normalizePath(.libPaths(), winslash = "/"), collapse = "; "), " |"),
  paste0("| renv active | ", if (nzchar(Sys.getenv("RENV_PROJECT"))) "yes" else "no", " |"),
  paste0("| renv.lock in working directory | ", if (file.exists("renv.lock")) "yes" else "no", " |"),
  "",
  "| Package | Version |",
  "|---|---|",
  vapply(pkgs, function(p) paste0("| ", p, " | ", pkg_version(p), " |"), character(1))
)
cat(paste(lines, collapse = "\n"), "\n")
if (!is.null(out)) {
  writeLines(lines, out)
  cat("Written to", normalizePath(out, winslash = "/"), "\n")
}
