<!-- Issue body for repositories without issue templates. Organisations with their own templates
     use those instead; the org profile (<skill>/references/org-profiles/) says which.
     Fill every field or write "none", and delete these comments before posting. -->
## Objective

<One line: the programme of work or objective this audit serves, or "standalone".>

## Product(s)

<What the repository produces and who consumes it: a model input, a report figure, a dataset, a package.>

## Stakeholder group(s)

<Who the work is for: the modelling team, a partner agency, a funder's reporting, the public.>

## Lead

<Who runs the audit. Name the original author as reviewer when that is someone else.>

## Context

<Why this matters and where it comes from: the repository and branch; the original author; what prompted the audit (a hand-off, a port to a new machine, outputs that could not be reproduced, a second audit after a merge); the reference outputs the audit compares against; the paper, working paper or meeting the pipeline supports. Say what is out of scope.>

## Acceptance criteria

- [ ] Baseline run (or snapshot) recorded before the first code change (workflow review §9 as-found)
- [ ] Three review documents in `docs/review/` (science review, workflow review, findings log); README and `CLAUDE.md` synced from them
- [ ] A fresh clone without data stops early with a readable table of what is missing and where to get it
- [ ] A fresh clone with the documented data placed and a local config added runs end to end from the command line
- [ ] The original author's layout still runs the same tracked code
- [ ] Every changed output has a cause (a finding ID or a decision number)
- [ ] `git ls-files -ci --exclude-standard` is empty; no machine paths outside commented examples
- [ ] Original author has run the branch and signed off

## External partner(s)

<Data providers or collaborators outside the organisation whose terms or inputs the audit touches, or "none".>
