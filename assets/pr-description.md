<!-- Pull request description for an audit branch, written in Phase 9 from the findings log.
     Replace every <...> and keep the headings. The reader is the original author, who may
     not have followed the issue, so say what changed and what did not before anything else. -->

<Opening note to the original author, in your own voice: the repository now runs on your machine; what you set out to do (make it runnable by anyone, including them, without changing what it computes); how the commits are organised; and the issue number. For example: "Hey <author>. I have it set up that I can run this repo and everything looks good. Next, I wanted to use this as a test case of a workflow anyone can run, including on your original code. <Analyst> and Claude tried to be diligent about tracking changes; each type of change is in its own commit. Fixes #N.">

## Changes made

<One paragraph per theme, bold theme first, then what changed and why, naming files and functions. Keep to what a reader needs to trust the branch; the detail is in the findings log §6.>

**Paths** (`<driver.R>`). <Repo-relative defaults; `config.local.R` gitignored and sourced after the defaults; the root anchor or working-directory guard, and what the wrong directory used to do; `dir.create(recursive = TRUE)`; interactive-only and platform-only calls guarded so the script runs under `Rscript`.>

**Input manifest** (`R/_setup.R`). <One place that records every input: source, terms, target path, expected shape. `fn.check_inputs()` reports what is present and stops early if a required input is missing; `fn.pull_all()` fetches what is downloadable and skips what is on disk. The driver, its error messages and the README read from the one manifest, so they cannot drift apart.>

**New downloads or shipped inputs.** <Which inputs were "supply by hand" and are now fetched or shipped, with provenance, and which sections that made reproducible.>

**Graceful degradation.** <What now runs, loudly, without each optional input, and what it falls back to.>

**Docs.** <README sections rewritten or added; `CLAUDE.md`; the review documents under `docs/review/`.>

## Needs examination

<Numbered. The scientific items from the findings log §8, deliberately left unchanged so outputs stay comparable. For each: what you saw and where, what you measured, and the question for the author. Shape: "**1. <Source> publishes <field> in <unit A>, not <unit B>.** <Where it shows.> `<function>` uses it as <unit B>. That is inherited from the legacy script, and I deliberately left the arithmetic alone so output stays comparable with the verified legacy grids; it does compound the existing <caveat>, by roughly <factor> rather than the <factor> the README estimates.">

1. <item>

## Also flagged for review

<Numbered, continuing the count. Behavioural items with their decision number, and the small fixes the first cold run exposed, each with the measurement that justified it. Shapes: "The endpoints serve the current compilation, not a pinned vintage; anyone holding existing data keeps it, only a fresh clone gets the new one." "Every download helper now raises R's 60-second `download.file` timeout; the archives are 100 to 230 MB." "A `1e-9` tolerance was tighter than float32 epsilon, so a fully covered cell landed about 2.4e-8 over 1 in <n> cells. I measured this before changing anything.">

2. <item>
3. <item>

## Acceptance checklist

<Copy the findings log §9. Each box cites where the evidence lives: a section of the workflow review or the findings log, a commit, a checksum CSV. Leave the author's box open; they tick it.>

- [ ] Baseline recorded before the first code change (workflow review §9 as-found; commit `<sha>`)
- [ ] Fresh clone without data stops early with the missing-input table (workflow review §9 as-left)
- [ ] Fresh clone with data and a minimal `config.local.R` runs end to end under `Rscript` (workflow review §9 as-left; `docs/review/<md5 compare>.csv`)
- [ ] Independent interactive run on the same commit gives identical outputs (workflow review §9 as-left)
- [ ] Every changed output has a cause (findings log §6; outputs commit `<sha>`)
- [ ] `git ls-files -ci --exclude-standard` empty; no machine paths outside commented examples (findings log §9)
- [ ] Original author has run the branch on the original machine

## Running it back on the original machine

<The exact `config.local.R` the author needs and nothing more. Say which keys keep their defaults and why (their data is already where the driver looks; the geodatabase is found by extension), and that downloads skip what they already hold, so their existing inputs and therefore their existing outputs are unchanged. Name the one new fetch, if any.>

```r
# config.local.R, in the repo root: restores the output location the driver used to hardcode
<key> <- '<the author's path, copied from the old driver>'
```

The first run should reproduce the previous outputs. That is the check worth making before trusting anything else here.
