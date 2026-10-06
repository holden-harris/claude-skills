# Template A: Science and Objectives Review (`docs/review/science-review.md`)

## How to use this template

Document A tells a reader what the pipeline does and why, in the shape of a research article: objectives, context, data sources, methods, results, discussion. It is for anyone who needs to understand or cite the work (the original author, a reviewer, a new analyst, a reader of the paper that used the outputs). It is the stable document of the three: drafted in Phase 2, corrected in Phase 5, finalised in Phase 9, and revised in place on later audits with a line in its version history.

Rules that keep it trustworthy:

- Every statement cites where it comes from: a file and line, a README section, a commit, a paper, or an interview with the author (write "author, interview, date"). What the code does not explain is marked "unexplained" rather than guessed.
- File-level detail (which file, which function, which folder) lives in Document B. A says what was done scientifically and why; B says how to run and maintain it.
- Figures carry "what to look for" captions, not just titles.
- Methods questions the audit raises go in §7 and in Doc C §8, and the arithmetic in the code stays as it is until the author decides.
- Three to eight pages. Plain, precise prose; numbers in tables.

Below, each section has a heading to copy, guidance in a blockquote (delete it when writing), and an example drawn from a real audit. The examples are illustrations of shape from other repositories; nothing in them is a fact about the repository being audited, and names of people in them are replaced by roles in square brackets.

---

# Science and Objectives Review: <repository name>

## 0. Header

> One block at the top. Repository and remote; the commit reviewed (line numbers elsewhere refer to it); original author(s); reviewer(s); date; status (draft, agreed with the author, superseded by <date>); how to cite this review; version history (one line per revision: date, what changed, which issue).

Example:

```
Repository: WFS-FEM/GFISHER (main at 3e4dea1). Original author: [author].
Reviewers: [analyst], with Claude Code. Date: 1 Oct 2026. Status: draft, for the author's review.
Version history: 2026-10-01 first draft (issue #2).
```

## 1. Summary

> About 150 words: what the code produces, from what, for whom, and the one or two things a reader must know before using the outputs.

Example (EcospaceBasemap): "Builds the static habitat, management-area, fleet-port and survey-region grids for the West Florida Shelf Ecospace model as ESRI ASCII rasters on a common 5 arc-minute grid. Habitat layers are proportions that sum to one per water cell; `sum1/` is the Ecospace input. The work consolidates three legacy codebases, and every module was verified cell by cell against the legacy grids except GFISHER and sum-to-1, which use a newer geodatabase." (README, lines 1-18 and 753-769.)

## 2. Objectives

> The questions the pipeline answers or the products it delivers; the downstream consumer and what it needs (format, grid, units, cadence); what "correct" means for these outputs (identical to a reference, within a tolerance, qualitatively sensible); scope and explicit non-goals.

Example (RedTideMaps): "Deliver monthly Karenia brevis concentration surfaces (cells/L) on the Ecospace grid as ASCII drivers, from FWC cell counts, satellite products and a species-distribution model, with a monthly rerun that an operator can run unattended. Non-goal: estimating red tide mortality; that happens in the ecosystem model." (README "Pipeline" and "Monthly rerun".)

## 3. Introduction and context

> Why the pipeline exists; the system or problem; its history (legacy scripts it replaced, earlier versions, who wrote what); related repositories and how data flows between them; programme or funding; the key literature. Cite the README, the commit history and the author's interview.

Example (GFISHER): "GFISHER turns FWRI side-scan habitat mapping and the 3LABS video survey into Ecospace inputs: sum-to-1 habitat basemaps, per-group MaxN heatmaps and habitat affinities. The basemap stage overlaps with EcospaceBasemap; whether it belongs here is tracked in issue #3." (`docs/issue2-review-gfisher-repo-plan.md` §1-2.)

## 4. Data sources

> One short paragraph or table row per source, at the scientific level: provider, collection method, spatial and temporal coverage, vintage (which version the pipeline used), known limitations, citation or URL. Say which sources cannot be redistributed and why. File names, sizes and download instructions belong in Doc B §3.

Example row: "FWC Seagrass Habitat in Florida (statewide compilation): polygons from aerial photo-interpretation, 1980s to present, served as the current compilation rather than a pinned release (the September 2026 download had 86,173 features). Public." (EcospaceBasemap README "Knowing which vintage you hold".)

## 5. Scientific methods

> One subsection per stage, in run order. For each: purpose; the method in plain words; key parameters and assumptions, each with the justification found in the code or README, or marked "unexplained"; alternatives considered or rejected and why; references. Where a parameter is a methods choice rather than a fact, say so; it is a candidate for §7 and Doc C §8.

Example (GFISHER stage 1, from `CLAUDE.md` architecture notes): "Reef density divides by scanned area, not cell area, then shrinks toward a region x depth-bin mean (`target = 'stratum'`). Smoothing and inverse-distance alternatives exist in the code and were rejected; the file header says why. Reef is forced to zero deeper than 300 m (`depth.max.reef`), unexplained in the README."

Example (EcospaceBasemap §2.3): "Gaps in the GFISHER survey (61% of water cells) are filled by inverse-distance weighting (power 4, eight neighbours) with `anchor.zero = 'both'`. The function's own documentation says this anchoring biases the fill downward; the driver passes it without comment, to match the legacy maps. Methods question for the author (Doc C §8)."

## 6. Results

> The final products and what they show: figures with "what to look for" captions; key numbers in a table; QC checks the code performs and their outcomes on the reviewed run; verification against reference or legacy outputs (identical, within tolerance, not comparable, with the reason). Cite Doc B §9 for the run evidence.

Example table (EcospaceBasemap README "Verification against the legacy scripts"):

| Module | Result |
|---|---|
| Depth (1, 5, 10, 15, 30 min) | identical; max diff 9.5e-7 m (float32 rounding) |
| Artificial reefs | correlation 1.0000 on all four classes; max diff 6e-5 from cell-area method |
| GFISHER, sum-to-1 | not directly comparable: new 2026 geodatabase, product restructured |

## 7. Discussion

> Interpretation and intended use; known caveats ranked by how much they could affect a downstream result (one line each, pointing to the stage); open methods questions for the author, each with the evidence and the options, marked "needs examination" and mirrored in Doc C §8; suggested scientific follow-ups and the issue that tracks each.

Example caveat (EcospaceBasemap README "Known caveats" 2): "Artificial reef layers are relief-weighted indices, not proportions (§2.4): units of metres, roughly 10x the true covered fraction; the source publishes relief in feet, so the inflation may be nearer 25x. Needs examination; arithmetic left unchanged so outputs stay comparable with the verified grids."

Example methods question (GFISHER §4.1c): "For the two sparse young stanzas (10 and 41 occupied cells) the random stanza assignment dominates: a layer's affinity can swing from 0 to 1 with the seed. Options: average over many seeds, raise the pooling threshold, or assign expected stanza fractions. A modelling judgement for the author, tracked in issue #5."

## 8. References

> Literature, data citations with access dates, related repositories and issues, the legacy scripts drawn on. Use the citation style the group uses elsewhere.

## 9. Appendices

> 9.1 Glossary of terms and variable names (the code's names next to their meaning and units). 9.2 Figure and table list with sources. 9.3 Version history of this document, if it did not fit in §0.
