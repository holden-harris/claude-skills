# Local path overrides for <driver.R>.
#
# Copy this file to config.local.R in the repo root and edit it. config.local.R is
# gitignored, so machine-specific paths never reach the repository. This is the only
# file you should need to touch to run the pipeline on another machine.
#
# The driver sources it AFTER setting its repo-relative defaults and BEFORE reading any
# input, so uncomment only the lines you want to change. `dir.repo` (the repo root) is
# already defined at that point and can be used below.
#
# Inputs that cannot ship with the repo (and how to get them) are listed in README.md
# under "Getting the data". One block per key: what it is and why you would change it,
# the default, and the assignment commented out.


# Folder holding the inputs that cannot ship: <the large or restricted files, by name>.
# Point this at a shared drive or a synced folder to avoid keeping a second copy. The
# repo default matches the original author's layout, so the author needs no override.
# Default: file.path(dir.repo, 'data', '<vintage>')
# dir.data <- 'D:/shared/<project>/data/<vintage>'
# dir.data <- file.path('C:/Users/<author>/<institution>',          # the original author's
#                       '<shared folder>/data/<project>/<vintage>')  # layout, kept as an example


# Where generated outputs are written. The tracked deliverables stay inside the repo by
# default so a rebuild shows in `git diff`; redirect the whole tree, or nothing.
# Default: file.path(dir.repo, 'output')
# dir.out <- 'D:/<project>-output'
# dir.out <- 'C:/Users/<author>/OneDrive - <institution>/<model>/output'   # the original author's layout


# Seed for the random draws in stage <k> (fn.<stage_k>). Any fixed integer makes the run
# reproducible run to run; NULL restores the unseeded behaviour. Changing it changes
# <the outputs that depend on the draw> and everything downstream.
# Default: 1
# seed <- 1


# Keys not listed here keep their defaults. When the audit adds a key, add its block here,
# its default to the SETTINGS block of the driver, and its row to README > Configuration,
# all in the same commit, so the three cannot drift.
