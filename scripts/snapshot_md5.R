# snapshot_md5.R ---------------------------------------------------------------------------
# Purpose: fingerprint every file under an output folder (size, MD5, MD5 with CRLF turned
#   into LF, modification time) so the outputs of two runs can be compared file by file,
#   and compare two such snapshots into the markdown table B section 9 and C need
#   (output group | identical | changed | line endings only | added | removed | cause).
#
# Usage:
#   Rscript snapshot_md5.R snapshot <dir> <out.csv> [--pattern "<regex>"]
#   Rscript snapshot_md5.R compare <before.csv> <after.csv> [--md]
#
# Inputs:
#   snapshot: <dir>, searched recursively. Files whose name matches --pattern are included
#             (case-insensitive; default \.(asc|csv|tif|tiff|rds|RData|Rdata|txt|json|png|pdf)$).
#             In PowerShell put the pattern in single quotes so $ survives.
#   compare:  two CSVs written by `snapshot` (columns path, md5, md5_lf). A CSV with only
#             `file` or `path` and `md5`, like the RStudio hand-off block writes, is accepted;
#             line-ending-only differences then count as changed.
# Outputs:
#   snapshot: <out.csv> with columns path (relative to <dir>, forward slashes), bytes, md5,
#             md5_lf, mtime. md5_lf is the MD5 after CRLF -> LF for text-like extensions
#             (asc, csv, txt, json, prj) and a copy of md5 for everything else.
#   compare:  counts, then a markdown table grouped by the top-level folder of each path
#             (Cause column left empty for the analyst), then the changed / line-endings-only /
#             added / removed paths. With --md only the markdown is printed, ready to paste.
# Exit status: 0 on success, 2 on a usage error, 1 (via stop()) on any other failure.
#
# Base R only (utils, tools). No shell calls. Forward slashes in every path written.
# Untested in the authoring session (no R available); the first local run is the acceptance test. Report problems in the skill's issue tracker.

options(warn = 1)

USAGE <- c(
  "Usage:",
  "  Rscript snapshot_md5.R snapshot <dir> <out.csv> [--pattern \"<regex>\"]",
  "  Rscript snapshot_md5.R compare <before.csv> <after.csv> [--md]",
  "",
  "snapshot: fingerprint the files under <dir> (recursive) into <out.csv>.",
  "compare:  classify every path as identical, line-endings-only, changed, added or removed",
  "          and print a markdown table grouped by top-level folder. --md prints only the",
  "          markdown, for pasting into a document.")

DEFAULT_PATTERN  <- "\\.(asc|csv|tif|tiff|rds|RData|Rdata|txt|json|png|pdf|prj)$"
TEXT_EXT_PATTERN <- "\\.(asc|csv|txt|json|prj)$"
STATUS_LEVELS    <- c("identical", "changed", "line-endings-only", "added", "removed")

fn.usage_exit <- function(msg = NULL) {
  if (!is.null(msg)) message("snapshot_md5.R: ", msg)
  message(paste(USAGE, collapse = "\n"))
  quit(save = "no", status = 2)
}

# Forward slashes everywhere, including paths normalizePath() hands back on Windows.
fn.fwd <- function(p) gsub("\\", "/", p, fixed = TRUE)

fn.md_escape <- function(x) gsub("|", "\\|", x, fixed = TRUE)

# Snapshot ---------------------------------------------------------------------------------

#' MD5 of a file with every CRLF turned into LF, so a checkout with core.autocrlf compares
#' equal to one without. Only 0x0D bytes immediately before a 0x0A are dropped; a lone CR
#' stays. Falls back to the plain MD5 (with a message) if the file cannot be read as raw.
fn.md5_lf <- function(path, bytes) {
  plain <- unname(tools::md5sum(path))
  if (is.na(bytes) || bytes <= 0) return(plain)
  res <- tryCatch({
    bytes_raw <- readBin(path, what = "raw", n = bytes)
    cr <- which(bytes_raw == as.raw(0x0d))
    cr <- cr[cr < length(bytes_raw)]                     # a trailing CR has no byte after it
    if (length(cr) > 0) cr <- cr[bytes_raw[cr + 1L] == as.raw(0x0a)]
    if (length(cr) == 0) {
      plain                                             # no CRLF at all: same as md5
    } else {
      tmp <- tempfile(fileext = ".lf")
      on.exit(unlink(tmp), add = TRUE)
      writeBin(bytes_raw[-cr], tmp)                     # guarded: x[-integer(0)] would be empty
      unname(tools::md5sum(tmp))
    }
  }, error = function(e) {
    message("snapshot_md5.R: could not compute md5_lf for ", path, " (", conditionMessage(e),
            "); using md5 instead")
    plain
  })
  res
}

fn.snapshot <- function(dir, out, pattern) {
  if (!dir.exists(dir)) stop("Folder to snapshot does not exist: ", dir, call. = FALSE)
  dir_norm <- fn.fwd(normalizePath(dir, winslash = "/", mustWork = TRUE))
  dir_norm <- sub("/+$", "", dir_norm)

  rel <- list.files(dir_norm, pattern = pattern, recursive = TRUE, ignore.case = TRUE,
                    full.names = FALSE)
  rel <- sort(fn.fwd(rel), method = "radix")             # C-locale order, same on every OS
  full <- file.path(dir_norm, rel)
  info <- file.info(full, extra_cols = FALSE)
  keep <- !is.na(info$isdir) & !info$isdir
  rel <- rel[keep]
  full <- full[keep]
  info <- info[keep, , drop = FALSE]

  if (length(rel) == 0)
    message("snapshot_md5.R: no files under ", dir_norm, " match the pattern ", pattern)

  md5 <- unname(tools::md5sum(full))
  md5_lf <- md5
  is_text <- grepl(TEXT_EXT_PATTERN, rel, ignore.case = TRUE)
  for (i in which(is_text)) md5_lf[i] <- fn.md5_lf(full[i], info$size[i])

  snap <- data.frame(path   = rel,
                     bytes  = sprintf("%.0f", info$size),  # plain digits, never 1e+05
                     md5    = md5,
                     md5_lf = md5_lf,
                     mtime  = format(info$mtime, "%Y-%m-%d %H:%M:%S"),
                     stringsAsFactors = FALSE)

  out_dir <- dirname(out)
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(out_dir)) stop("Could not create the folder for ", out, call. = FALSE)
  write.csv(snap, out, row.names = FALSE)

  cat(sprintf("Snapshot: %d file(s) under %s\n", nrow(snap), dir_norm))
  cat(sprintf("Written:  %s\n", fn.fwd(normalizePath(out, winslash = "/", mustWork = FALSE))))
  invisible(snap)
}

# Compare ----------------------------------------------------------------------------------

fn.read_snapshot <- function(f) {
  if (!file.exists(f)) stop("Snapshot CSV not found: ", f, call. = FALSE)
  d <- read.csv(f, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
  if (!"path" %in% names(d) && "file" %in% names(d)) names(d)[names(d) == "file"] <- "path"
  if (!all(c("path", "md5") %in% names(d)))
    stop("Snapshot CSV needs columns 'path' and 'md5' (found: ", paste(names(d), collapse = ", "),
         "): ", f, call. = FALSE)
  if (!"md5_lf" %in% names(d)) d$md5_lf <- d$md5
  d$path <- fn.fwd(d$path)
  d
}

fn.compare <- function(before_csv, after_csv, md_only) {
  before <- fn.read_snapshot(before_csv)
  after  <- fn.read_snapshot(after_csv)

  paths <- sort(union(before$path, after$path), method = "radix")
  ib <- match(paths, before$path)                        # NA where the path is only in after
  ia <- match(paths, after$path)                         # NA where the path is only in before
  eq <- function(x, y) !is.na(x) & !is.na(y) & x == y
  md5_b <- before$md5[ib];    md5_a <- after$md5[ia]
  lf_b  <- before$md5_lf[ib]; lf_a  <- after$md5_lf[ia]

  status <- ifelse(is.na(ib), "added",
            ifelse(is.na(ia), "removed",
            ifelse(eq(md5_b, md5_a), "identical",
            ifelse(eq(lf_b, lf_a), "line-endings-only", "changed"))))
  status <- factor(status, levels = STATUS_LEVELS)
  group <- ifelse(grepl("/", paths, fixed = TRUE), sub("/.*$", "", paths), "(root)")

  res <- data.frame(path = paths, group = group, status = status,
                    md5_before = md5_b, md5_after = md5_a, stringsAsFactors = FALSE)
  counts <- table(res$status)                            # one cell per STATUS_LEVELS entry
  by_group <- table(res$group, res$status)               # rows: groups; cols: STATUS_LEVELS

  md <- c("| Output group | Identical | Changed | Line endings only | Added | Removed | Cause |",
          "|---|---:|---:|---:|---:|---:|---|")
  for (g in rownames(by_group))
    md <- c(md, sprintf("| %s | %d | %d | %d | %d | %d |  |", fn.md_escape(g),
                        by_group[g, "identical"], by_group[g, "changed"],
                        by_group[g, "line-endings-only"], by_group[g, "added"],
                        by_group[g, "removed"]))
  if (nrow(by_group) > 1)
    md <- c(md, sprintf("| **Total** | %d | %d | %d | %d | %d |  |",
                        counts[["identical"]], counts[["changed"]], counts[["line-endings-only"]],
                        counts[["added"]], counts[["removed"]]))
  if (nrow(by_group) == 0) md <- c(md, "", "No files in either snapshot.")

  fn.list_block <- function(title, st, show_md5) {
    rows <- res[res$status == st, , drop = FALSE]
    if (nrow(rows) == 0) return(character(0))
    items <- if (show_md5) {
      sprintf("- `%s` (%s -> %s)", fn.md_escape(rows$path),
              substr(rows$md5_before, 1, 8), substr(rows$md5_after, 1, 8))
    } else {
      sprintf("- `%s`", fn.md_escape(rows$path))
    }
    c("", sprintf("**%s (%d)**", title, nrow(rows)), "", items)
  }
  md <- c(md,
          fn.list_block("Changed", "changed", TRUE),
          fn.list_block("Line endings only (same bytes once CRLF is read as LF)",
                        "line-endings-only", TRUE),
          fn.list_block("Added (only in after)", "added", FALSE),
          fn.list_block("Removed (only in before)", "removed", FALSE))

  if (!md_only) {
    cat(sprintf("Comparing snapshots\n  before: %s (%d file(s))\n  after:  %s (%d file(s))\n",
                before_csv, nrow(before), after_csv, nrow(after)))
    cat(sprintf("Counts: identical %d, changed %d, line-endings-only %d, added %d, removed %d\n\n",
                counts[["identical"]], counts[["changed"]], counts[["line-endings-only"]],
                counts[["added"]], counts[["removed"]]))
  }
  cat(md, sep = "\n")
  cat("\n")
  invisible(res)
}

# Arguments --------------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) fn.usage_exit()
mode <- args[1]
rest <- args[-1]

if (mode == "snapshot") {
  pattern <- DEFAULT_PATTERN
  positional <- character(0)
  i <- 1L
  while (i <= length(rest)) {
    a <- rest[i]
    if (a == "--pattern") {
      if (i == length(rest)) fn.usage_exit("--pattern needs a regex")
      pattern <- rest[i + 1L]
      i <- i + 2L
    } else if (startsWith(a, "--")) {
      fn.usage_exit(paste("unknown option", a))
    } else {
      positional <- c(positional, a)
      i <- i + 1L
    }
  }
  if (length(positional) != 2) fn.usage_exit("snapshot needs <dir> and <out.csv>")
  fn.snapshot(positional[1], positional[2], pattern)

} else if (mode == "compare") {
  md_only <- FALSE
  positional <- character(0)
  for (a in rest) {
    if (a == "--md") md_only <- TRUE
    else if (startsWith(a, "--")) fn.usage_exit(paste("unknown option", a))
    else positional <- c(positional, a)
  }
  if (length(positional) != 2) fn.usage_exit("compare needs <before.csv> and <after.csv>")
  fn.compare(positional[1], positional[2], md_only)

} else {
  fn.usage_exit(paste("unknown mode", mode, "(expected snapshot or compare)"))
}
