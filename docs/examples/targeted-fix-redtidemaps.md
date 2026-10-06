# Example: a targeted fix (RedTideMaps, issue #3, pull request #4, September 2026)

Source: `docs/issue3-hull-fix-plan.md` in https://github.com/WFS-FEM/RedTideMaps (253 lines). One issue, one bug, a written diagnosis and plan before any code changed. It is the model for the skill's `fix` mode (Appendix 1 of the Document C template). Excerpts are verbatim except that names of people are replaced by their roles, `[analyst]` and `[author]`; commentary follows each.

## Diagnosis first, in one paragraph

```
The long, thin, low-concentration polygons that run from the Panhandle to southwest Florida in
the combined maps (1991-01, 1996-08, ...) are produced by `fn.buffered_hulls()` in
`scripts/polygon_clipping_rt.R`. Every flagged month is a **buffered-hull fallback month** ...
The root cause is the clustering logic, not concaveman or the buffer: k-means with a within-SS
"elbow" (a) almost always returns k = 2, (b) cannot run at all for 4 to 7 positives, and (c)
when any cluster has fewer than 4 points the code falls back to **one hull around all points**,
which is exactly the case where the outliers should have been separated.
```

What to notice: symptom, location, mechanism and the sentence that rules out the alternatives, before any fix is proposed.

## Failure paths labelled, each tied to the cases it explains

```
**A. Small-cluster fallback hulls everything together (lines 70, 77 to 78).**
... Months: 1991-01 (clusters 2 + 35), 1996-08 (3 + 13), 1997-01 (3 + 26), 1998-02 (3 + 12), 1999-11 (1 + 44).

**B. The elbow is undefined for 4 <= n < 8 (lines 62 to 65).**
... Month: 1998-03 (6 positives spanning 337 km).
```

Then "Contributing factors, not bugs on their own", including "`kmeans()` is unseeded, so hull polygons (and therefore ASCII deliverables for fallback months) are not reproducible run to run." That line is an S-lens finding sitting inside a B-lens diagnosis; the skill's registers would hold it as its own row.

## Evidence with controls

```
| Month | n positive | Branch taken | Largest hull diagonal (km) | Band ratio | Flagged? |
|---|---|---|---|---|---|
| 1991-01 | 37 | A: k=2 gave sizes 2, 35 -> single hull | 543 | 3.3 | yes |
| 1998-03 | 6 | B: elbow undefined -> single hull | 373 | 1.5 | yes |
| 1996-07 | 14 | split 9, 5 | 140 | 1.5 | no |
```

"Every flagged month reproduces; none of the five control months does." A root cause that also explains why the unaffected cases are unaffected is the standard the skill asks for in Doc C §3.

## Downstream impact in the model's own terms

The document translates the artifact into what the ecosystem model would do with it ("the direct mortality response is a logistic in cells/L with inflection points of 50,000 to 400,000 cells/L ... the point is that the operational pipeline must not produce it unattended"). Document Doc A §7 is where this reasoning lives in the skill's layout.

## Fix design with a chosen default and a sensitivity case

A code sketch of the replacement (single-linkage clustering in base R, no new dependency), a parameters table, and a decision with its evidence: "default `hull_link_km = 75`, user-settable ... 50 km is the sensitivity case to report ... There is no literature value for this distance; it encodes the sampling spacing of the FWC coastal monitoring more than bloom biology." Alternatives considered are listed with the reason each was not chosen, and one of them ("raising the positive threshold") is moved to a separate issue because it "changes what a footprint means": the skill's `scientific` kind, deferred to the author.

## Decisions finalised before implementation

```
1. `hull_link_km = 75` as the default, overridable in `config.local.R` (section 6.2). Report
   50 km as the sensitivity case in the PR. Decided by [analyst].
```

## Steps with pauses, and acceptance criteria on fingerprints

Step 8: "Baseline before the full run. With R: `tools::md5sum(...)` saved to `out/5min/md5_before.csv`". Acceptance: "Every ASCII for a VIIRS or MODIS month has the same MD5 as in `md5_before.csv`; only `use == "pred"` months change. Report how many changed." and "Determinism: the `stopifnot()` block in the QA script passes (two calls on the same input give identical polygon lists)." The skill's `snapshot_md5.R compare` and the QA-script pattern in `references/verification.md` come from here.

## The kickoff prompt

```
We are fixing WFS-FEM/RedTideMaps issue #3 (spurious hull polygons in
fallback months) on branch 3-polygon-clipping-issues. The diagnosis and the
finalized plan are in docs/issue-3-hull-fix-plan.md. Read it fully first.
... work through it in order, pausing after step 7
(QA script results) and after step 9 (full run) to show me the evidence
before committing. ... Finish by reporting the section 8 acceptance
criteria as a checklist with evidence ..., then draft the PR description with "Fixes #3".
```

What to notice: the pause points are named in the prompt. The skill makes this the default behaviour (pauses 7 to 10) and lets the user widen or narrow them in Phase 6.

## What the skill adds over this document

- The document was never updated after it was uploaded; the results went into commit bodies and the pull request. C's status block and change log keep the record in one place.
- The kickoff prompt names `docs/issue-3-hull-fix-plan.md` while the file is `issue3-hull-fix-plan.md`; the resume rule reads the folder rather than a remembered name.
- A file-scope `set.seed(6)` elsewhere in the pipeline went unnoticed; the S lens inventories every random call before deciding what the seed should do.
