# AI Instructions for GoProX Project

## General Principles
- Always follow the standards and conventions in this file for all code, documentation, and communication.
- Do not use filler phrases like "Good idea!" or similar conversational fluff.
- Never require the user to remind you of project standards; treat this file as the source of truth.

## MANDATORY RELEASE CHECKLIST
**CRITICAL: This checklist MUST be completed before ANY release or dry run operation:**

1. **Create Major Changes Summary File** (MANDATORY)
   - Before any release or dry run, ALWAYS create/update: `docs/release/latest-major-changes-since-<BASE>.md`
   - Replace `<BASE>` with the previous version (no leading 'v')
   - This file MUST exist before the release process starts
   - The full-release script will error out if this file is missing

2. **Check for Uncommitted Changes**
   - Ensure `scripts/release/` directory is clean (no uncommitted changes)
   - Ensure `.github/workflows/` directory is clean (no uncommitted changes)
   - Commit and push all changes before proceeding

3. **Use Full Release Script**
   - Always use `scripts/release/full-release.zsh` for releases
   - Never run individual scripts unless specifically instructed

**FAILURE TO FOLLOW THIS CHECKLIST WILL RESULT IN RELEASE FAILURE**

## Issue Reference Format
- Always use the correct issue reference format: (refs #n) or (refs #n #n ...).

## Commit Message Standards
- Use imperative mood for commit messages.
- Reference issues using (refs #n) format.
- Summarize changes clearly and concisely.

## Output and File Handling
- All transient output must go in the `output/` directory.
- Never commit files in `output/`.
- Ensure `output/` is in `.gitignore`.

## Documentation
- Update all relevant documentation when scripts or workflows change.
- Use zsh code blocks for shell script examples in documentation and wiki pages.
- Document all new scripts and major changes in `RELEASE_PROCESS.md`.
- The AI assistant must read and stay up-to-date with all project documentation, including transient documents such as the generated issue list in `output/github_issues.md`, to maintain full project awareness and context.

## Communication
- Be concise and direct.
- Avoid unnecessary praise, conversational padding, or filler phrases.
- Focus on actionable steps and clear explanations.

## Linting and Automation
- Always ensure YAML and shell scripts pass linting before suggesting commits.
- Use project-specific linting rules (see `.yamllint`).

## Behavioral Guidelines
- Apply these rules to all work, suggestions, and communication for this project.
- Treat this file as the canonical source for project-specific standards and instructions.
- If a rule is ambiguous, ask for clarification before proceeding.

## Release Workflow Automation

- When the user requests a release, always use the `./scripts/release/full-release.zsh` script to perform the entire release process (version bump, workflow trigger, monitoring) in a single, automated step.
- By default, all test runs should be performed as dry runs (using `--dry-run`), unless a real release is explicitly requested.
- Do not run the bump-version, release, or monitor scripts individually unless specifically instructed.

## Issue Creation Automation

- Whenever the user requests an issue to be created, always create it as a GitHub tracker issue.
- Assign the issue to fxstein by default.
- Use the latest issues as a template for formatting and structure.
- When creating the issue statement, format the text using proper Markdown and multi-line input, avoiding explicit \n characters in the body.

## Release Testing

- Always perform test runs for releases as dry runs by default (using the dry-run option), unless a real release is explicitly requested by the user.

## Script Language Requirements

- All scripts in this project MUST be written in zsh and use zsh syntax.
- Never change scripts to bash or other shells for compatibility reasons.
- All shell scripts must have `#!/bin/zsh` shebang.
- Use zsh-specific features like `typeset -a` for arrays when appropriate.
- If debugging is needed, test with bash temporarily but always fix the root cause in zsh.

## GitHub Issue Awareness (AI Assistant)

- Periodically run the `scripts/maintenance/generate-issues-markdown.zsh` script and read the output in `output/github_issues.md`.
- Always keep up-to-date with the current open and closed issues on GitHub.
- Reference the correct issue numbers and titles when performing work, making suggestions, or committing changes.
- Use this awareness to ensure all work is properly linked to relevant issues and to provide accurate context during development and communication.

## Release Script Automation
- Always use `scripts/release/full-release.zsh` for all release and dry-run operations. This script performs version bumping, workflow triggering, and monitoring in a single automated process.
- For dry runs, use: `./scripts/release/full-release.zsh --dry-run` (this will run non-interactively and monitor the workflow).
- Default to this format whenever the user requests a release or dry run of the release process.
- **IMPORTANT**: Before any release or dry run, always check the entire `scripts/release/` directory for changes. Commit and push all changes in `scripts/release/` before running a release or dry run. The GitHub workflow uses the repository state on GitHub, not local changes. Failure to commit and push will result in the workflow using outdated scripts.
- If a full release (without `--dry-run`) is requested and there are changes in `scripts/release/`, first commit and push those changes, then perform a dry run. Only proceed with the real release if the dry run completes successfully.
- Whenever a release is requested (dry-run or real), always create or update a file in `docs/release` with a summary of major changes since the requested previous release. The filename must match the convention used by the release process: `docs/release/latest-major-changes-since-<BASE>.md` (where `<BASE>` is the previous version, no leading 'v'). This file must be created every time a release is requested, before the release process starts.

## GitHub Issue Management
- Whenever a new GitHub issue is created, immediately run `scripts/maintenance/generate-issues-markdown.zsh` to update the local Markdown issue list.
- After generating the issue list, read the output file (`output/github_issues.md`) to ensure you are memorizing and referencing the latest issues in all future work and communication.

## [Add more rules as needed...] 