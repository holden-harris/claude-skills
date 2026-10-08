# Skill Benchmark: code-audit

**Model**: claude-fable-5-1 for the runs; claude-sonnet-5-5 for the graders
**Date**: 2026-10-06T01:28:00Z
**Evals**: 1, 2, 3 (1 run each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 91% ± 10% | 56% ± 12% | +0.36 |
| Time | 1798.7s ± 1558.6s | 687.1s ± 606.1s | +1111.6s |
| Tokens | 135423 ± 29630 | 33052 ± 35003 | +102371 |
## Analyst notes (added after reading the grading files)

- **One run per arm.** The aggregator's header says three; this iteration ran each test case once with the skill and once without, so the spreads are across test cases, not repeats. Treat the pass rates as a first signal.
- **Time and token columns are not comparable.** Two runs (the EcospaceBasemap baseline and the GFISHER with-skill run) were cut off by a session limit before their timing was captured, so their zeros pull the no-skill averages down. The runs that were timed took 15 to 35 minutes and 250k to 430k tokens each, with and without the skill.
- **Where the skill made the difference.** EcospaceBasemap 16/17 vs 8/17: the structure (three documents, eight registers, kinds, statuses) and the planted defects the baseline missed (dropped NA-relief records, the workspace wipe, the unguarded plots). GFISHER 8/8 vs 4/8: mode detection (second audit), the carry-over block, no re-numbering of old findings, the drift check as the first run step. RedTideMaps 8/10 vs 7/10: the download timeout, the glossary and line references on findings.
- **Non-discriminating assertions.** "No GitHub write and no fabricated run evidence" passed in every arm; keep it as a guard, not as a measure.
- **Contamination to fix next iteration.** The rubric's example rows cite EcospaceBasemap at the very commit used by test case 1, so a with-skill run can pass several assertions by transcription. The next iteration needs a held-out repository that the rubric and examples never mention (a private WFS-FEM repository, or any R pipeline of the analyst's). The EcospaceBasemap grader also noticed that science review §3 carried related-repository statements from the template's examples; the templates now say explicitly that examples are illustrations of shape, not facts.
- **Form misses worth a template change (done in this commit).** The RedTideMaps stage table named one function; the stage-table header now asks for the main function. Four of 45 findings rows pointed at folders or data files with no line; the findings log now asks for the line of the code or text that establishes such a finding. Two of nine model subsections stated assumptions; the workflow review §5 now asks for an explicit "assumptions not stated in the code" line when that is the case.
- **Baseline strength.** The no-skill runs were strong on substance (one found a real pooling bug in GFISHER's site-level affinities; another found the stale 15-minute RedTideMaps deliverables). The skill's value in this iteration is structure, routing (what goes to the author), honesty about what was not run, and the second-audit behaviour, not raw finding count.
