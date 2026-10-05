# _setup.R -------------------------------------------------------------------------------
# Skeleton. Adapt to the repository; do not paste wholesale.
#
# Session setup for <driver.R>: package check, plot device, input manifest, input check.
# Base R only, so it can run before any package is attached. Sourced once at the top of
# the driver, right after the root-anchor check, which looks like this:
#
#   # Everything downstream is resolved from the working directory, so check it first.
#   if(!file.exists('<Project>.Rproj'))
#     stop('Set the working directory to the repo root - open <Project>.Rproj, or setwd() there. ',
#          'Currently: ', getwd())
#   source(file.path('R', '_setup.R'))

# Packages ---------------------------------------------------------------------------------
# Required by the live stages. Optional ones are reported, not required: say what each serves.
PACKAGES.REQUIRED <- c('sf', 'raster')
PACKAGES.OPTIONAL <- c('mgcv')

#' Stop early, with one install line, if any required package is missing.
#' Runs before any library() call so a missing package fails in the first second of a run
#' rather than partway through stage 2.
fn.check_packages <- function(pkgs = PACKAGES.REQUIRED, optional = PACKAGES.OPTIONAL){
  have <- function(p) vapply(p, requireNamespace, logical(1), quietly = TRUE)
  missing <- pkgs[!have(pkgs)]
  if(length(missing) > 0)
    stop('Missing R package(s): ', paste(missing, collapse = ', '),
         '\nInstall with:\n  install.packages(c(', paste0('"', missing, '"', collapse = ', '), '))',
         call. = FALSE)
  opt.missing <- optional[!have(optional)]
  if(length(opt.missing) > 0)
    message('Optional package(s) not installed (only needed for non-default options or ',
            'legacy modules): ', paste(opt.missing, collapse = ', '))
  invisible(TRUE)
}

# Plot device ------------------------------------------------------------------------------
#' Open a recording graphics window when that makes sense, and do nothing otherwise.
#' Replaces the old Windows-only recording-device call, which failed under Rscript and on
#' non-Windows systems and warns when .SavedPlots does not exist.
fn.plot_device <- function(){
  if(interactive() && .Platform$OS.type == 'windows'){
    try(rm(.SavedPlots, envir = .GlobalEnv), silent = TRUE)   # RGui plot history
    try(dev.new(record = TRUE), silent = TRUE)
  }
  invisible(NULL)
}

# Input manifest ---------------------------------------------------------------------------
#' One row per input the driver reads, with its resolved path, which stages need it,
#' whether it is required, and where it comes from. `how` is one of:
#'   repo    ships with the repository
#'   auto    downloaded by the driver on first run
#'   manual  must be obtained by hand (data that cannot be redistributed)
#'   derived produced by a sibling repository or supplied by the author
#' The driver, its error messages and README "Getting the data" all read from this table.
#' `source` is what a user sees when the input is missing: what, how big, from whom, where.
#' @param dir.data Folder holding the inputs that cannot ship (set in config.local.R).
#' @param file.template Path to the grid template the stages share.
#' @return data.frame with columns key, stage, required, how, path, source.
fn.data_manifest <- function(dir.data, file.template){
  rbind(
    data.frame(key = 'template', stage = '1,2', required = TRUE, how = 'repo',
               path = file.template,
               source = 'data/template/ (ships with the repo)'),
    data.frame(key = 'survey', stage = '2', required = TRUE, how = 'manual',
               path = file.path(dir.data, '<survey file>.csv'),
               source = '<Provider> <survey name> <years>, ~<size>. Request from <contact>; place in dir.data.'),
    stringsAsFactors = FALSE)
}

#' Check every input before any long computation and stop with instructions if a
#' required one is missing. Prints a status table so a run log records what was used.
#' @param manifest The data.frame from fn.data_manifest().
#' @param stop.on.missing Stop (TRUE) or only warn (FALSE) when a required input is absent.
#' @return The manifest with a logical `present` column, invisibly.
fn.check_inputs <- function(manifest, stop.on.missing = TRUE){
  m <- manifest
  m$present <- !is.na(m$path) & nzchar(m$path) & file.exists(m$path)

  cat('\nInput check\n', strrep('-', 100), '\n', sep = '')
  cat(sprintf('  %-13s %-8s %-8s %-8s %s\n', 'input', 'stage', 'need', 'how', 'status / path'))
  for(i in seq_len(nrow(m)))
    cat(sprintf('  %-13s %-8s %-8s %-8s %s  %s\n', m$key[i], m$stage[i],
                if(m$required[i]) 'required' else 'optional', m$how[i],
                if(m$present[i]) 'OK     ' else 'MISSING', m$path[i]))
  cat(strrep('-', 100), '\n', sep = '')

  miss <- m[!m$present, ]
  if(nrow(miss) > 0){
    cat('\nMissing input(s):\n')
    for(i in seq_len(nrow(miss))) cat(sprintf('  %-13s %s\n', miss$key[i], miss$source[i]))
    cat('  See README.md > Getting the data, and config.local.example.R for the path overrides.\n')
  }

  short <- m$key[!m$present & m$required]
  if(length(short) > 0){
    msg <- paste0('Missing required input(s): ', paste(short, collapse = ', '), '.')
    if(isTRUE(stop.on.missing)) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }
  invisible(m)
}
