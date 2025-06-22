# AI Instructions for GoProX Project

## General Principles
- Always follow the standards and conventions in this file for all code, documentation, and communication.
- Do not use filler phrases like "Good idea!" or similar conversational fluff.
- Never require the user to remind you of project standards; treat this file as the source of truth.

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

- When the user requests a release, always perform the following steps in order:
  1. Run the version bump script with `--auto --force` (e.g., `./scripts/release/bump-version.zsh --auto --force`).
  2. Run the release script with `--force` (e.g., `./scripts/release/release.zsh --force`).
  3. Start the release monitor for the specific release version (e.g., `./scripts/release/monitor-release.zsh <version>`).

- Ensure these steps are followed automatically and in sequence unless the user explicitly requests a different workflow.

## Issue Creation Automation

- Whenever the user requests an issue to be created, always create it as a GitHub tracker issue.
- Assign the issue to fxstein by default.
- Use the latest issues as a template for formatting and structure.
- When creating the issue statement, format the text using proper Markdown and multi-line input, avoiding explicit \n characters in the body.

## [Add more rules as needed...] 