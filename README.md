# claude-skills

Claude Code skills for scientific analysis work, written to be portable across repositories and organisations. Each skill is a folder with a `SKILL.md` and its own README, references, scripts and assets.

| Skill | What it does | Invoke |
|---|---|---|
| [`code-audit`](code-audit/) | Audit an existing analysis repository with the analyst in the loop: make it run and reproducible for the user, the original author and a fresh clone; produce a science review, a plain-language workflow review and a living findings-and-decisions log; fix the code through a tracked issue, branch and draft pull request | `/code-audit` |

## Install

Clone this repository, then copy or link the skill folder where Claude Code looks for skills:

- Personal (every repository on your machine): `~/.claude/skills/<skill>`. On Windows, for example, `mklink /D %USERPROFILE%\.claude\skills\code-audit C:\Repos\claude-skills\code-audit` from an administrator prompt, or copy the folder and copy again after each `git pull`.
- Project (one repository, shared with its collaborators): `<repo>/.claude/skills/<skill>`, committed.
- Claude Desktop, Cowork and cloud sessions: package the folder with the skill-creator skill (`python -m scripts.package_skill code-audit`) and upload the `.skill` file in your claude.ai skills settings.

Each skill's README lists its prerequisites and modes.

## Contributing

Open an issue describing the change, branch from it as `N-short-description`, keep commits split by type (code, docs, outputs, housekeeping, record), and open a draft pull request with `Fixes #N`. The `code-audit` skill's own workflow applies to this repository too.
