# Org profile: WFS-FEM

For repositories under the GitHub organisation **WFS-FEM** (RedTideMaps, GFISHER, EcospaceBasemap, the private EwE input repositories) and the planning repository WFS-FEM/Ops. Detect by the remote owner `WFS-FEM`; confirm with the user in Phase 1. The code repositories have no `.github/ISSUE_TEMPLATE/` of their own; the templates live in Ops (`.github/ISSUE_TEMPLATE/task.yml`, `decision.yml`, `meeting.yml`), and the conventions below come from the Ops README, Ops `docs/decisions.md`, and GFISHER's `CLAUDE.md` and README "For collaborators".

The usual people: the original code author is Dave Chagaris; the analyst running audits is Holden Harris; the Lead field takes `Holden`, `Dave` or `Other`.

| Field | Value |
|---|---|
| Detect by | Remote owner `WFS-FEM` |
| Issue template | A plain issue in the code repository whose body carries the Task template's fields (next section); the Ops Task form itself when the issue is opened in Ops |
| Labels | `code` for an audit, plus `docs`, `pipeline`, `EwE`, `decision`, `blocked` as they apply. The Ops label set is `meeting, code, EwE, pipeline, docs, outreach, paper, decision, blocked`; a code repository may also carry GitHub's defaults (RedTideMaps #3 was labelled `bug`) |
| Project board | Every piece of work is an issue in the most relevant repository. Issues in Ops join the organisation project **WFS-FEM Operationalization** (project #4) automatically; issues in code repositories are added from the issue sidebar, then the project fields are set in the sidebar |
| Sub-issues | Methods questions (Doc C §8) become sub-issues of the audit issue in the same repository (GFISHER #2 had #3 and #5) |
| Decision issues | For a decision that affects a method or a shared convention, a `[Decision]` issue (Ops template `decision.yml`, label `decision`) with the fields below; the outcome is summarised in Ops `docs/decisions.md` |
| Branch | `N-short-description`, created from the issue's Development sidebar (`2-review-gfisher-repo`, `3-polygon-clipping-issues`) |
| Pull request | Draft against `main`; body carries `Fixes #N`, the acceptance checklist and a note for Dave; ready at Phase 9 with Dave requested as reviewer |
| Commit subject | Imperative, `(issue #N)` at the end |
| Commit split | `code` / `docs` / `outputs` / `housekeeping`, plus this skill's `record` |
| Trailer | `Co-Authored-By: Claude <model> <noreply@anthropic.com>` when Claude co-authored (for example `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`) |
| Merge policy | Merge commit (RedTideMaps PR #2 and GFISHER PR #4 both did); delete the branch |
| Decisions | Numbered in Doc C §7, and recorded in the issue that raised them |
| External decision log | One line in Ops `docs/decisions.md` for each decision that affects a method or a shared convention |
| Risk register | Ops `docs/risk-register.md`; a risk the audit finds that needs action becomes a task issue |
| Review documents | `docs/review/` in the audited repository (GFISHER's first review, before this convention, lives at `docs/issue2-review-gfisher-repo-plan.md`) |

## Issue body fields (from the Ops Task template)

Fill these in the issue body, in this order, then set the matching project fields in the sidebar; the dropdowns only record the choices in the issue text.

| Field | Options or content |
|---|---|
| Objective | `I. Automation`, `II. Integration`, `III. Communication`, `PM (project management)`. An audit is usually III (documented, replicable) or I |
| Product(s) | `A. EwE model update`, `B. SEDAR Mrt`, `C. Shiny App`, `D. R package`, `E. IEA/ESR`, `F. Peer-reviewed paper`, `G. Report`, `H. Other` (multi-select) |
| Stakeholder group(s) | `A. SEFSC Gulf Fisheries Branch / SEDAR`, `B. Gulf IEA / ESR`, `C. Fisheries managers`, `D. Ecosystem modelers`, `E. Science community`, `F. Fishers and public`, `G. Funder (NOAA RESTORE reporting)`, `H. Other` (multi-select) |
| Lead | `Holden`, `Dave`, `Other` |
| Context | Why this matters and where it comes from (cite the paper, working paper or meeting); for an audit, the Doc A §1-3 summary and the three run targets |
| Acceptance criteria | A checklist; becomes Doc C §9 and the PR body |
| External partner(s), if any | Free text (FWRI, the Hu lab, SEFSC analysts) |

Project fields to set in the sidebar: Objective, Stakeholder group, Product, Priority (P0 to P3), Phase (the quarter the item should finish), Target date, Lead, External partner(s). Product, Stakeholder group and Lead are the three to set on every issue.

## Decision issues (from `decision.yml`)

Title `[Decision] ...`, label `decision`, fields **Decision needed**, **Options considered** (numbered), **Needed by**, **Outcome and rationale (fill in when decided)**. Open one for every `scientific` finding the author must rule on (a units change, a pooling threshold, whether background-level detections define a bloom footprint), link it as a sub-issue of the audit, and leave the arithmetic as it is until the outcome is filled in.

## Ops decision log

Row format in `docs/decisions.md`, one line per decision, the discussion staying in the issue:

```
| Date | Decision | Where discussed | Status |
| 2026-10-02 | GFISHER stage 2 stanza draw is seeded (seed = 1, overridable in config.local.R); whether one realisation is enough is issue #5 | GFISHER #2, PR #4 | Adopted |
```

Add a line at merge (Phase 9) for each decision that affects a method or a shared convention (a seed policy, a default linkage distance, which repository produces a shared layer); decisions that only tidy one repository stay in Doc C §7. In cloud sessions the Ops repository must be attached before the line can be committed; otherwise give the user the line to paste.

## What the audit documents cite

GFISHER `CLAUDE.md` states the house rules the P and R lenses check in every WFS-FEM repository: machine-specific paths never go in tracked files (defaults repo-relative, overrides in gitignored `config.local.R`, documented key by key in `config.local.example.R`); three people must be able to run the same tracked code (the author with his layout, Holden, a fresh clone); nothing Windows-only or interactive-only runs unguarded; random draws are seeded; commits are split by type with `(issue #N)` in the subject. Where the audited repository lacks one of these, that is a finding, and the fix follows the GFISHER and RedTideMaps shape so the repositories stay alike.
