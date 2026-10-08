# Second local run: a held-out private repository, audit mode (7 and 8 October 2026)

## The run

- **Repository.** A private spatial-transcriptomics pipeline (R, Seurat v5, DESeq2 from Bioconductor; Xenium data) written by another author on macOS, with the raw data on the author's lab drive and the region polygons on their desktop. The analyst is a collaborator on the repository, not its author. The repository, the author and the results stay out of this public record; findings below are described by their shape.
- **Why held out.** Nothing in the skill's rubric, templates, examples or evals mentions this repository. Before the run, the skill's author wrote a private list of expected findings from the code (24 items across the eight lenses, plus form checks) and compared the documents against it afterwards. The analyst did not see the list.
- **Machine.** A new Windows 11 machine with R 4.5.3, the skill cloned into `~/.claude/skills/code-audit` on branch `1-code-audit-skill`, no Xenium data, Seurat and DESeq2 not installed.
- **Mode chosen.** `audit`, degraded. The skill opened an issue from the default profile's issue body, a branch named from the issue, the findings log, and a draft pull request with the acceptance checklist; it handed the baseline run to the author as a block posted on the pull request, with fingerprints before and after and a `sessionInfo()` capture, and left every run-time cell reading "pending: run on the author's machine".
- **State when graded.** Pause 5 (statuses), four commits on the branch (scaffold and ignore rules; a one-character pre-baseline fix; the record of that fix and the hand-off; the Phase 5 record). Documents: findings log 278 lines, science review 406, workflow review 494.

## Grade against the private list

| Lens | Expected (by shape) | Found | Where |
|---|---|---|---|
| P | Machine-specific `setwd()` in the run script | yes | P3 |
| P | Data and polygon paths as literals in the author's layout; no local override file | yes | P1, P2; workflow review §2.2 |
| P | No root anchor, no tracked project file | yes | P3 |
| P | No package check; one package attached by a sourced file and declared nowhere; Bioconductor dependency; no versions recorded | yes | P4, P5, R5 |
| R | The polygon files are the key analytic input, gitignored by a blanket rule, with the file-to-sample mapping only in code | partial | described in workflow review §3.2 and routed to the author; no register row |
| R | A diagnostics block reads a gitignored checkpoint of a superseded run | yes | R4, with the sharper point that no code path produces that run any more |
| R | A checkpoint reload ignores later changes to the marker panels or thresholds | yes | R7 |
| R | Tracked outputs carry no record of the commit or settings that produced them | yes | B4, R8 |
| B | A misplaced parenthesis in the statistics-table function (the one high-severity bug on the list) | yes | B1, found by the parse sweep (18 of 19 files parsed), fixed before the baseline as decision 4 with evidence that the fix changes no output |
| B | Group membership inferred from sample names by regex rather than from metadata | yes | B5, in three files |
| B | Mixed Seurat v4 and v5 arguments (`slot =` beside `layer =`) | yes | B7 |
| B | Per-sample z-scoring makes the "unclassified" rule sample-relative | yes | M4 and science review §5.3 |
| B | A file named "template" defines the per-sample function used everywhere | no | low severity |
| D | Header comments contradict the README on which DE method is primary | yes | D2 |
| D | A `[TODO: source]` placeholder in the README | yes | D7 |
| D | A README claim about the smallest attainable p-value describes a test the code does not run | yes | D9, plus the point that the cell-level test's adjustment is Bonferroni, which no document states |
| D | A README open item answerable from the code (which cells a detection floor is computed on) | yes | workflow review §4.2 answers it |
| M | Per-cell argmax design, per-sample floor, compositional t-tests at n = 3, pseudobulk versus cell-level DE, a second correction on a subset of the same tests | yes | M3, M5, M7; science review §5 |
| M | Blinding and label unblinding recorded; thresholds derived without group labels | partial | science review §3 records the blinding; the "derived without group labels" statement from the run script is not carried into the science review |
| S | No `set.seed()`; every random step rests on a library default (module scoring, PCA, UMAP) | yes | S1 and workflow review §6, plus a jitter seed in a plot the list missed |
| T | No timings; checkpoints exist and are gitignored | yes | T1; workflow review §8 |
| E | Dead configuration (superseded polygon paths); commented-out code | partial | E3; the commented code is not flagged (trivial) |
| E | Functions never called from the drivers | yes | E1, E4 |
| E | Duplicate tracked figures; superseded run folders kept beside current ones | yes | E2; R4 and workflow review §7 |

21 of 24 found, 2 partial, 1 missed; the miss and the partials are all low severity.

**Found beyond the list**, each checked against the code by the skill's author after the run:

- Three groups of tracked tables that no tracked code writes (R1 to R3): confirmed, the only table writer in the function files is the cell-count table, and the files were added in commits that changed no code.
- The sensitivity filter rewrites one label column while both DE functions select cells on another, so the sensitivity runs never reach DE (M2): confirmed in the filter and the two DE functions; the run also showed the eight DE heatmaps byte-identical across the three runs of a region.
- Genes that define a cell type's identity panel are re-tested as DE candidates within that cell type (M1): confirmed, the identity panel and the candidate list share the same genes for two cell types.
- A protocol statement contradicted by the committed table it describes (D1).
- Evidence notes that recompute two committed tables from other committed tables after the parse fix (agreement to 1.6e-14 and exact), which is what let a one-character fix go in before the baseline with a clear conscience.

## Form

- Three documents with the names the skill uses; registers in lens order with kind, severity and status; 49 rows; decisions numbered, dated and owned; the hand-off block is complete (fetch the branch, fingerprints before and after, logged run, `sessionInfo()`, restore the outputs, what to paste back).
- Two rows carry no line (a table with no producing code; a repository-wide absence); the template asks for a line on every row.
- No run was claimed that did not happen. The pre-baseline fix followed the Phase 4 rule for code that cannot run at all, with a decision number and evidence.
- The science review header still read "draft (Phase 2 orientation)" and the workflow review §0 still said "Phase 2 draft: §1 and §2 only" after the Phase 5 commit had filled the results, discussion and §3 to §8. The workflow review numbered its verification subsections 9.1 and 9.3.
- The pause 5 message listed bare ID ranges ("P1-P6", "R1-R3") with one-line summaries in brackets; the analyst asked what the letters mean.

## Changes made to the skill from this run

1. Pause 5 opens with the lens key and presents each lens as its own short table under a heading that names the lens in full; the key line now sits in the findings log §2 and in the §0 guidance of the science review and the workflow review, and the README shows it. A documentation row that would rewrite a scientific statement goes to the author before the text changes.
2. A record commit that fills sections of the science review or the workflow review updates that document's §0 status, phase and version lines in the same commit (working rule).
3. The Phase 4 rule for code that cannot run at all now says the minimum fix is a numbered decision with evidence that it changes no output, and that the baseline runs on the fixed commit.

4. The ten pauses have names (scope, orientation check, scaffold, baseline go-ahead, triage, commit plan, commit, outputs regeneration, destructive git, ready for review). Every pause message opens with a progress line that gives the pause and the phase by number and name and names the next pause; steps are cited with their findings log §5 title; the findings log status block records the phase and the pauses passed. From the analyst's second request after the run: the numbers alone sent them back to the README.

Open after this run: the baseline on the author's machine, and the analyst's triage at pause 5.
