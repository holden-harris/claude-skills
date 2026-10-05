# Org profile: default

The generic profile, used when no other profile in this folder matches the remote owner or the repository's `.github/ISSUE_TEMPLATE/`. Pick it in Phase 1 and confirm with the user. To write a profile for another organisation, copy this file, keep the field names in the first column, change the values, and add the organisation's own sections below the table; `wfs-fem.md` is a filled example.

| Field | Default value | What it decides |
|---|---|---|
| Detect by | Nothing matches: no profile names the remote owner and the repository has no templates | How Phase 1 picks the profile; a new profile names the GitHub owner(s) and any template files that identify it |
| Issue template | A plain GitHub issue from `<skill>/assets/issue-body.md` (context, acceptance checklist, the three run targets, scope); the repository's own template when `.github/ISSUE_TEMPLATE/` exists | What the Phase 3 issue looks like and which fields must be filled |
| Labels | Whatever the repository already has (`gh label list`); none are created | Labels added at issue creation; a profile may name a fixed set |
| Sub-issues | Plain issues linked as sub-issues of the audit issue | Where methods questions (Doc C §8) and carried-over steps go |
| Decision issues | None; a methods question is an ordinary sub-issue | Whether `scientific` findings open a special issue type |
| Branch | `N-slug` from the issue's Development sidebar or `gh issue develop`; `audit/<slug>` when issues are not used | Branch naming in Phase 3 |
| Pull request | Draft against the default branch; body carries `Fixes #N` and the Doc C §9 checklist; ready at Phase 9 | How the PR is opened and when it is marked ready |
| Commit subject | Imperative, no trailing period, suffix `(issue #N)` | The subject style checked at every commit |
| Trailer lines | Left to the user's own convention; ask once in Phase 1 and record the answer in Doc C §1 | What follows the commit body (co-author lines, sign-offs) |
| Merge policy | Asked at Phase 9: merge commit unless the repository's history shows squash merges | How the PR lands and whether the branch is deleted (yes, by default) |
| Decisions | Doc C §7 only, numbered, dated and owned | Where decisions are recorded |
| External decision log | None | Whether a line is added to a log outside the repository at merge |
| Risk register | None | Whether audit findings feed an external register |
| Review documents | `docs/review/` in the audited repository: `science-review.md`, `workflow-review.md`, `issueN-<slug>-log.md` | Where A, B and C live |
| Reviewer | The original author, requested at Phase 9 | Who is asked to review the PR |

## Notes on the fields

- **Issue template.** The asset body has the same bones as most task templates (context, acceptance criteria as a checklist), so a profile usually adds fields on top of it rather than replacing it.
- **Labels.** The default creates none because an audit should not change a repository's label set without asking; a profile that owns its labels can list them.
- **Sub-issues and decision issues.** Methods questions outlive the pull request, so they need an issue of their own; a profile whose organisation records decisions formally names the issue type and where the outcome is summarised.
- **Branch.** `N-slug` keeps the issue number in every `git log --oneline` and lets GitHub link branch, issue and PR; `audit/<slug>` is the fallback for repositories that do not use issues (then the PR body has no `Fixes #N` line and Doc C §0 says so).
- **Commit subject suffix.** `(issue #N)` makes each commit findable from the issue and the issue from the commit; a profile that uses `#N` prefixes or conventional-commit types changes this one field.
- **Trailer lines.** The default imposes no `Co-Authored-By` line; where the user wants one, write it exactly as they give it and use it on every commit.
- **Merge policy.** Asked rather than assumed, because squashing destroys the per-commit evidence the audit was careful to write; put the question once at Phase 9 with that trade-off stated.
- **Decisions.** Numbered decisions in Doc C §7 are what commit bodies and Doc B §9 cite; an external log, where a profile has one, gets one summary line per decision, never the discussion.
- **Review documents.** `docs/review/` keeps A, B and C beside the code they describe, so they travel with every clone and every PR; a profile may choose another folder but should not move them out of the repository.

## Writing a new profile

1. Copy this file to `<owner>.md` and fill the "Detect by" row with the GitHub owner and any template files.
2. Change only the values that differ; a row that matches the default can say "as default".
3. Add a section for each external record (decision log, risk register, project board) with its exact row format, so the skill can append a line without guessing.
4. Name the usual people and roles if the organisation is small enough for that to help.
