# GitHub workflow

Read this at the start of Phases 3, 7 and 9, and whenever `gh` is unavailable. It covers the issue, the branch, the draft pull request, the mapping from `gh` commands to the GitHub MCP tools for cloud sessions, the commit style with three real examples, the merge, and the things never to do. The org profile (`<skill>/references/org-profiles/`) decides what varies between organisations: the issue template, labels, branch naming, merge policy, trailer lines and any external records.

## The issue

Create the issue in Phase 3, after orientation has been confirmed at pause 2, because acceptance criteria are only worth writing once "is this what the code does?" has been answered. In `resume` mode the issue already exists; in `review-only` mode nothing is created; in `own past code` mode with no remote, offer to create a repository first (ask, then `gh repo create`).

The issue carries three things:

- **Context**: what the repository does, who wrote it, why it is being audited and what is out of scope, in a few lines drawn from the Doc A §1-3 drafts, with the three run targets named.
- **Acceptance criteria** as a checklist. These become Doc C §9 and are copied into the pull request body, so write them as statements that evidence can show true: a run from a fresh clone exits 0; a missing input stops the run with a table naming the file; `git ls-files -ci --exclude-standard` is empty; the author confirms a run on their machine. The last one stays open until the author ticks it.
- **Labels**, when the repository has them; the profile lists which.

The profile decides the template. A repository with `.github/ISSUE_TEMPLATE/` uses its own forms; otherwise use `<skill>/assets/issue-body.md`. Search first (`gh issue list --search "<keyword>" --state all`) so the audit does not duplicate an issue the author already opened.

Methods questions (the `scientific` findings that go to Doc C §8) become **sub-issues** of the audit issue, so they outlive the pull request and the author can answer them at their own pace. Create the issue, then link it: `gh api -X POST repos/{owner}/{repo}/issues/{N}/sub_issues -F sub_issue_id=<id>`, where `<id>` is the database id (`gh api repos/{owner}/{repo}/issues/{M} --jq .id`), not the issue number. Where the profile has decision issues, open the methods question as one.

Show the issue title and body, the branch name and the pull request body at pause 3, and wait for a yes before the first write.

## The branch

Default name `N-slug`: the issue number, a hyphen, and the title in a few lowercase words (`2-review-gfisher-repo`). The profile may say otherwise; when issues are not used at all, `audit/<slug>`.

Create it from the issue so GitHub links the two:

- Locally: `gh issue develop N --checkout --name N-slug`. It branches from the default branch head, lists the branch under the issue's Development heading and checks it out.
- In the browser: the issue's **Development** sidebar, "Create a branch", then "Checkout locally", which prints the two commands to run in the clone (`git fetch origin`, `git checkout N-slug`).
- In cloud sessions: `mcp__github__create_branch` from the default branch, then `git fetch origin && git checkout N-slug`.

`gh issue develop` uses GraphQL, which some proxies block. If it fails, `git switch -c N-slug` from the default branch head, push with `-u`, and link the branch from the Development sidebar. Confirm with `git branch --show-current` and a clean `git status` before the first commit.

## The draft pull request

Open it in Phase 3 step 5, as soon as the first `docs` commit (C, with the A and B drafts) is pushed, so the author has somewhere to watch from the start and the evidence has somewhere to attach.

```
git push -u origin N-slug
gh pr create --draft --base main --title "<issue title> (issue #N)" --body-file <body.md>
```

The body carries `Fixes #N` (merging then closes the issue), the acceptance checklist copied from Doc C §9, and a line saying the review documents live in `docs/review/`. As the audit proceeds the evidence goes in: the baseline result line and comparison table from Doc B §9 after Phase 4; the before/after table of every `outputs` commit; the run matrix after Phase 8. Update the body with `gh pr edit N --body-file <body.md>`; use a comment (`gh pr comment N --body-file <note.md>`) for progress the author should see as it happens, since body edits notify nobody.

At Phase 9, after pause 10 and the pre-ready check on C, rewrite the body from `<skill>/assets/pr-description.md` and then:

```
gh pr ready N
gh pr edit N --add-reviewer <author-login>
```

Marking ready before the pre-ready check is on the never-do list: a ready pull request with placeholders or `open` rows tells the author the work is finished when it is not.

## Tool mapping

Local sessions use `gh`. Cloud sessions use the GitHub MCP tools, or `gh api` with a REST path where that is simpler. `gh pr view`, `gh pr ready`, `gh pr edit` and `gh issue develop` go through GraphQL and can fail behind a proxy where the REST paths work.

| Action | Local `gh` | Cloud equivalent |
|---|---|---|
| Create issue | `gh issue create --title ... --body-file ... --label ...` | `mcp__github__issue_write` (method `create`) |
| Comment on issue | `gh issue comment N --body-file ...` | `mcp__github__add_issue_comment` |
| Read an issue | `gh issue view N` | `mcp__github__issue_read`, or `gh api repos/{owner}/{repo}/issues/{n}` |
| Link a sub-issue | `gh api -X POST repos/{owner}/{repo}/issues/{n}/sub_issues -F sub_issue_id=<id>` | `mcp__github__sub_issue_write` |
| Create branch from issue | `gh issue develop N --checkout --name N-slug` | `mcp__github__create_branch`, then `git fetch origin && git checkout N-slug` |
| Read a PR | `gh pr view N` (GraphQL; may fail behind a proxy) | `mcp__github__pull_request_read`, or `gh api repos/{owner}/{repo}/pulls/{n}` (REST; works) |
| Create PR | `gh pr create --draft --base main --title ... --body-file ...` | `mcp__github__create_pull_request` with `draft: true` |
| Update PR body | `gh pr edit N --body-file ...` | `mcp__github__update_pull_request`, or `gh api -X PATCH repos/{owner}/{repo}/pulls/{n} -F body=@body.md` |
| Request reviewer | `gh pr edit N --add-reviewer <login>` | `mcp__github__update_pull_request` (reviewers), or `gh api -X POST repos/{owner}/{repo}/pulls/{n}/requested_reviewers -f 'reviewers[]=<login>'` |
| Comment on PR | `gh pr comment N --body-file ...` | `mcp__github__add_issue_comment` (a PR takes issue comments) |
| Mark ready | `gh pr ready N` | `mcp__github__update_pull_request` with `draft: false`. REST has no ready-for-review path, so without the MCP tool use the GraphQL mutation `gh pr ready` itself uses: `gh api graphql -f query='mutation { markPullRequestReadyForReview(input: {pullRequestId: "<node id>"}) { pullRequest { isDraft } } }'` (node id from `gh api repos/{owner}/{repo}/pulls/{n} --jq .node_id`) |
| Push | `git push -u origin <branch>` | the same; the repository must be attached with push access first |
| Merge | `gh pr merge N --merge --delete-branch` | `mcp__github__merge_pull_request` (merge method `merge`), then `gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/<branch>` |
| Create a repository for code with no remote | `gh repo create <owner>/<name> --private --source . --push` | `mcp__github__create_repository`, then `git remote add origin <url>` and push; only after asking the user |

## Cloud limitations

- Another repository (the Ops repository for a decision-log line, a sibling repository that holds an input) must be attached to the session before it can be read or written. Ask for it to be attached rather than reporting that it cannot be reached.
- Pushes are refused when the GitHub App is not installed for that repository. The remedy is on the user's side: install the app for the repository (github.com/apps/claude/installations/select_target) or reconnect GitHub in the claude.ai settings. Say so plainly; the skill then re-attaches the repository and continues, and the commits are safe locally in the meantime.
- GraphQL-backed `gh` subcommands can fail behind the proxy; the table above gives the REST or MCP route for each.
- Run steps cannot happen in the cloud at all; `<skill>/references/verification.md` has the hand-off text. GitHub writes still work, so the issue, branch and draft pull request are created as usual and the evidence arrives from the analyst's machine.

## Commit style

**Subject**: imperative mood, no trailing period, ending `(issue #N)` in the default profile. Say what the commit does to the repository, not what the session did (`Seed the stanza assignment`, not `Fixed seeding`).

**Body**, wrapped at about 80 columns, in this order:

1. The problem, in one or two sentences, with the finding IDs in parentheses.
2. The change, file by file: `path: what changed`, with indented bullets when a file has several changes.
3. The finding IDs and decision numbers this commit closes, where the text above has not already named them.
4. An `Evidence:` paragraph with numbers: `identical()` results, MD5 counts, cells changed, timings. Evidence is what lets a reader trust the commit without rerunning it.
5. `Left out, deliberately:` when something was consciously not changed (the history rewrite the author has not decided on, the method that stays as it is), so nobody reads the omission as an oversight.
6. The trailer lines the profile asks for.

Three real commits from the GFISHER audit (WFS-FEM/GFISHER, issue #2), printed with `git log -1 --format='%s%n%n%b' <sha>`.

**`code` commit with evidence (0299a4d):**

```
Read the species list with readxl and seed the stanza assignment (issue #2)

R/video_dataset.R
  - xlsx::read.xlsx -> readxl::read_excel for both sheets of Master Species
    List.xlsx, so no Java runtime is needed (P5). Verified: with seed 1 the
    stage 2 table is identical() to the one produced by the xlsx reader.
  - new argument seed=1 on fn.make_gfisher_videodataset, applied on entry.
    The multistanza step draws lengths (rtruncnorm) and pairs observed lengths
    with individuals (sample.int), so gag and red grouper stanza assignment was
    different on every run (R1). seed=NULL restores the unseeded behaviour.
    Existing callers keep working.
  - two comments carrying the author's machine path removed.
process GFISHER data.R: seed <- 1 in SETTINGS (overridable in config.local.R),
  passed to fn.make_gfisher_videodataset.
R/_setup.R: 'readxl' replaces 'xlsx' in the required-package list.

Evidence (stages 2 and 3 rerun with seeds 1, 1 and 2): same seed gives
identical tables and byte-identical rasters; per-species, per-station and
occupied-cell totals are identical across seeds; only the split among stanzas
moves. How much that split matters for the affinities is issue #5.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

**`record` commit (a565205):**

```
Record the stochasticity check on the stanza maps (issue #2)

Section 4.1b: same-seed and cross-seed tests on stages 2 and 3, the
invariants that hold for any seed, the size of the per-cell differences,
and the methods question now tracked in issue #5.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

**`housekeeping` commit (7d1c659):**

```
Stop tracking legacy data and a stale output folder; align .gitignore with what is tracked (issue #2)

Untracked with git rm --cached (files stay on disk and in history):
  data/East_Master_Hab_data_Dissolve_byMicro_13Sept24.gdb   78 MB, one dissolved
    layer, input only to the retired two-geodatabase legacy function
  data/FWRI_East_Gulf_Mapping_2023.gdb                     125 MB, 2023 vintage of
    the two layers the current code reads from the 2026 geodatabase
  data/Video Count Data4ChagarisTake2.xlsx                  14 MB, referenced only
    in a comment; superseded by the 3LABS CSVs
Removed (in history if ever needed):
  data/size_at_age.csv        referenced by no code; stanza sizes come from the
                              spp_stanzas_sizes sheet of Master Species List.xlsx
  output/affinity_selratio/   untagged folder no current code writes; its five
                              files duplicate an older run of affinity_selratio_mice/

.gitignore rewritten so that what is tracked is exactly what is not ignored
(git ls-files -ci --exclude-standard is empty), grouped and commented:
machine/session files, inputs that cannot ship, generated outputs (the
tracked deliverables are named), author scratch. Clone size does not shrink
because the blobs remain in history; a history rewrite is a separate
decision for the author.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

The housekeeping example lists every file it touches with size and reason, and its last sentence is the "left out, deliberately" note in prose form: the history rewrite was not done, and the body says so and says whose decision it is.

## Commit types

| Kind | One line |
|---|---|
| `code` | Changes what the code does or how it is configured; body carries the finding IDs closed and an `Evidence:` paragraph |
| `docs` | README, `CLAUDE.md`, A and B, the config example; no code, no outputs |
| `outputs` | Regenerated tracked deliverables, one commit after pause 8; body carries the before/after table with a cause per row |
| `housekeeping` | Moves to `hoard/` or `archive/`, `git rm --cached`, `.gitignore`; body lists every file |
| `record` | Changes only documents (C, and Doc B §9) to capture evidence: a baseline, a test, a verification |

Keep types apart because they are read differently: a reviewer skims `docs`, reads `code` closely, and checks `outputs` against its table. A commit that mixes them hides the one that matters.

**Record commits land before the code that relies on their evidence.** The baseline record precedes the first `code` commit; the stochasticity record (a565205 above) sits before the dead-code and bug-fix commits that cite it; the Phase 8 record precedes `outputs`. If the session ends after the record and before the fix, the evidence is already in the branch and the next session continues from C.

## Merge

Merge with a **merge commit** by default, because the reasoning lives in the individual commits and their bodies (squashing GFISHER's PR #4 would have folded 25 commits of evidence into one message). Squash only when the repository's own convention says so. Delete the branch after the merge; the commits live on in the default branch, and a stale `N-slug` invites someone to commit to it later. Where the profile has external records (a decisions log, a risk register), add their lines at this point.

A merge made with a merge commit is reversible with `git revert -m 1 <merge sha>`; a problem found afterwards is usually a small follow-up commit, not a revert.

## Never do

- `git add -A` in a repository with large data; stage by path, and read `git status` before every commit.
- Commit `data/` or `output/` paths by accident. The tracked deliverables are named in `.gitignore` comments for a reason; anything else under those trees needs a decision first.
- Force-push or rewrite history on a branch anyone else has pulled.
- Rewrite history at all without a numbered decision in Doc C §7, the audit's own draft branch, and pause 9.
- Push a scientific change without the author's decision; `scientific` items go to Doc C §8 and a sub-issue, and the arithmetic stays as it is.
- Open the pull request as ready before the pre-ready check on C (no `open` rows, no placeholders, every unticked §5 step carried to a sub-issue, every changed output explained).
- Write a run time, exit code or checksum into a commit body that you did not see yourself or receive from the analyst.
