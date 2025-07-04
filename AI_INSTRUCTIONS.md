# AI Instructions for GoProX Project

## Design Principles and Architecture
**CRITICAL: Before beginning any work on this project, you MUST read and understand the Design Principles document: `docs/architecture/DESIGN_PRINCIPLES.md`**

**MANDATORY READING REQUIREMENT: Whenever you are asked to read AI Instructions, you MUST also read the Design Principles document immediately after. These two documents work together and both are required for complete project context.**

This document establishes the foundational architectural decisions and design patterns that guide all development work. It covers:
- Simplicity as the core principle
- Consistent parameter processing using zparseopts
- Human-readable configuration management
- Progressive enhancement approach
- Platform consistency requirements
- Error handling and recovery patterns
- Documentation-driven development

**IMPORTANT:** When making any significant design or architectural decisions, always ask if the decision should be documented in the Design Principles document for future reference and consistency.

## General Principles
- Always follow the standards and conventions in this file for all code, documentation, and communication.
- Do not use filler phrases like "Good idea!" or similar conversational fluff.
- Never require the user to remind you of project standards; treat this file as the source of truth.

## Terminology Standards
- **Summary Usage**: Never use the term "executive summary" in any work. Always use "summary" or "<topic> summary" (e.g., "release summary", "feature summary", "implementation summary").
- Maintain consistent terminology across all documentation, commit messages, and communication.

## MANDATORY RELEASE CHECKLIST
**CRITICAL: This checklist MUST be completed before ANY release or dry run operation:**

1. **Create Major Changes Summary File** (MANDATORY)
   - Before any release or dry run, ALWAYS create/update: `docs/release/latest-major-changes-since-<BASE>.md`
   - The required content and formatting for this file are defined in [`docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md`](docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md). You MUST read and follow those instructions.
   - This file MUST exist before the release process starts
   - The full-release script will error out if this file is missing

2. **Check for Uncommitted Changes**
   - Ensure `scripts/release/` directory is clean (no uncommitted changes)
   - Ensure `.github/workflows/` directory is clean (no uncommitted changes)
   - Commit and push all changes before proceeding

3. **Use Full Release Script**
   - Always use `scripts/release/gitflow-release.zsh` for releases
   - Never run individual scripts unless specifically instructed

4. **Output File Requirements** (CRITICAL)
   - ALL transient output files MUST be placed in the `output/` directory
   - NEVER create test files, logs, or any output in the repo root
   - This includes release notes, test files, debug output, etc.
   - The `output/` directory is in `.gitignore` for a reason
   - Violation of this rule will result in immediate cleanup and correction

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

## Git Operations (CRITICAL)
- **NEVER run git operations in interactive mode** when performing automated tasks, commits, merges, or rebases.
- **Always use non-interactive git commands** to avoid opening editors (vim, nano, etc.) that can hang the process.
- **For rebases and merges**: Use `--no-edit` flag or set `GIT_EDITOR=true` to prevent interactive editor opening.
- **For commits**: Use `-m` flag to specify commit messages directly on command line.
- **For interactive rebases**: Avoid `git rebase -i` unless explicitly requested by user.
- **When conflicts occur**: Resolve them programmatically and use `git add` to stage resolved files.
- **Examples of safe git commands**:
  ```zsh
  git commit -m "message"                    # Non-interactive commit
  git merge --no-edit                        # Non-interactive merge
  GIT_EDITOR=true git rebase --continue     # Non-interactive rebase continue
  git rebase --abort                         # Abort stuck operations
  ```
- **If git operations hang**: Use `Ctrl+C` to interrupt and then `git rebase --abort` or `git merge --abort` to reset state.

## Release Workflow Automation

- When the user requests a release, always use the `./scripts/release/gitflow-release.zsh` script to perform the entire release process (version bump, workflow trigger, monitoring) in a single, automated step.
- By default, all test runs should be performed as dry runs (using `--dry-run`), unless a real release is explicitly requested.
- Do not run the bump-version, release, or monitor scripts individually unless specifically instructed.

## Issue Creation Automation

- Whenever the user requests an issue to be created, always create it as a GitHub tracker issue.
- Assign the issue to fxstein by default.
- **IMPORTANT**: fxstein is the user's official GitHub handle. When the user asks to assign an issue to "myself" or "themselves," this means assign to fxstein.
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

## Logging and Debug Output Requirements

- **MANDATORY**: Always use the structured logger module (`scripts/core/logger.zsh`) for all output, including debug information.
- **NEVER use random echo statements** for debug output, status messages, or any user-facing information.
- **Use appropriate logger functions**:
  - `log_debug` for debug information and troubleshooting
  - `log_info` for general information and status updates
  - `log_warn` for warnings and non-critical issues
  - `log_error` for errors and critical issues
- **Debug output must be structured** and use the logger's debug level for consistency across all scripts.
- **Remove any existing echo statements** used for debugging and replace them with appropriate logger calls.
- **Exception**: Only use echo for actual user prompts or when the logger is not available (very rare cases).

## GitHub Issue Awareness (AI Assistant)

- Periodically run the `scripts/maintenance/generate-issues-markdown.zsh` script and read the output in `output/github_issues.md`.
- Always keep up-to-date with the current open and closed issues on GitHub.
- Reference the correct issue numbers and titles when performing work, making suggestions, or committing changes.
- Use this awareness to ensure all work is properly linked to relevant issues and to provide accurate context during development and communication.

## Release Script Automation
- **ALWAYS use the new simplified top-level release script**: `./scripts/release/release.zsh` for all release and dry-run operations
- **For AI/Automation**: Use batch mode with all parameters specified: `./scripts/release/release.zsh --batch <type> --prev <version> [options]`
- **For Interactive Use**: Use interactive mode: `./scripts/release/release.zsh` (default) or `./scripts/release/release.zsh --interactive`
- **Release Types**: 
  - `dry-run`: Test release process without actual release (any branch)
  - `official`: Production releases (main/develop/release/* branches)
  - `beta`: Beta releases (release/* branches)
  - `dev`: Development releases (feature/*/fix/* branches)
- **Default to batch mode for automation** whenever the user requests a release or dry run of the release process
- **IMPORTANT**: Before any release or dry run, always check the entire `scripts/release/` directory for changes. Commit and push all changes in `scripts/release/` before running a release or dry run. The GitHub workflow uses the repository state on GitHub, not local changes. Failure to commit and push will result in the workflow using outdated scripts.
- If a full release (without `--dry-run`) is requested and there are changes in `scripts/release/`, first commit and push those changes, then perform a dry run. Only proceed with the real release if the dry run completes successfully.
- Whenever a release is requested (dry-run or real), always create or update a file in `docs/release` with a summary of major changes since the requested previous release. The filename must match the convention used by the release process: `docs/release/latest-major-changes-since-<BASE>.md` (where `<BASE>` is the previous version, no leading 'v'). This file must be created every time a release is requested, before the release process starts.

**Examples for AI/Automation:**
```zsh
# Dry run for testing
./scripts/release/release.zsh --batch dry-run --prev 01.50.00 --minor

# Official release with monitoring
./scripts/release/release.zsh --batch official --prev 01.50.00 --minor --monitor

# Beta release with specific version
./scripts/release/release.zsh --batch beta --prev 01.50.00 --version 01.51.00

# Development release
./scripts/release/release.zsh --batch dev --prev 01.50.00 --patch
```

**Legacy Scripts**: The old `scripts/release/gitflow-release.zsh` is now the unified release script and should be used for all release operations. The `full-release.zsh` script has been deprecated and its functionality merged into `gitflow-release.zsh`.

## GitHub Issue Management
- Whenever a new GitHub issue is created, immediately run `scripts/maintenance/generate-issues-markdown.zsh` to update the local Markdown issue list.
- After generating the issue list, read the output file (`output/github_issues.md`) to ensure you are memorizing and referencing the latest issues in all future work and communication.

## GitHub Command Intermediate Documents (MANDATORY)
**CRITICAL: For any GitHub issue or PR creation commands with complex formatting or long content, ALWAYS create an intermediate document first to avoid formatting issues and process hangs.**

**Rationale**: Complex GitHub CLI commands with long bodies, multiple parameters, or special characters can cause formatting issues, syntax errors, or process hangs. Creating intermediate documents ensures reliable command execution and proper formatting.

**Requirements**:
- **Create intermediate document** for any GitHub command with:
  - Long body text (more than 200 characters)
  - Multiple parameters or complex formatting
  - Special characters or markdown formatting
  - Multiple labels or assignees
  - Complex issue/PR descriptions

- **Document location**: `output/` directory
- **Naming convention**: `output/<command_type>_<timestamp>.md` (e.g., `output/pr_body_20250629_153000.md`)
- **Content format**: Clean markdown with proper formatting

**Implementation Process**:
1. **Create intermediate document** in `output/` directory
2. **Write content** with proper markdown formatting
3. **Read document content** into variable or use file reference
4. **Execute GitHub command** using the document content
5. **Clean up** intermediate document after successful execution

**Examples**:
```zsh
# Create intermediate document for complex PR
cat > output/pr_body_$(date +%Y%m%d_%H%M%S).md << 'EOF'
## Summary
Complex PR description with multiple sections...

## Requirements
- Feature A
- Feature B

## Motivation
Detailed explanation...

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
EOF

# Use document in GitHub command
gh pr create --title "title" --body-file output/pr_body_*.md --assignee fxstein --label enhancement
```

**Benefits**:
- ✅ **Reliable execution** - Avoids command line length limits
- ✅ **Proper formatting** - Maintains markdown structure
- ✅ **Error prevention** - Reduces syntax and formatting issues
- ✅ **Easy editing** - Can review and modify content before execution
- ✅ **Cleanup** - Intermediate files are in `output/` directory (gitignored)

**Enforcement**:
- **MANDATORY** for all complex GitHub commands
- **Failure to follow** will result in immediate correction
- **Always use** for issue/PR creation with detailed content
- **Clean up** intermediate files after successful execution

**Common Use Cases**:
- Creating detailed GitHub issues with multiple sections
- Creating pull requests with comprehensive descriptions
- Adding complex labels and assignees
- Including formatted markdown content
- Multi-line descriptions or requirements

## Pull Request Issue Closure Rules (MANDATORY)
- **NEVER assume whether a PR closes an issue** - always ask the user if the PR closes the entire issue or is just a partial implementation
- **Use "Related to #X" instead of "Closes #X"** unless explicitly told by the user that the PR closes the issue
- **Let the user determine issue closure** - only they can decide if the PR fully addresses the issue requirements
- **Be conservative with issue closure** - it's better to under-claim than over-claim the scope of work
- **Ask explicitly**: "Does this PR close issue #X entirely, or is this a partial implementation?"

**RATIONALE**: Prevents incorrect assumptions about issue scope and ensures proper issue management. Only the user knows the full requirements and can determine when an issue is truly complete.

## Pull Request Assignment and Labeling (MANDATORY)
**CRITICAL: For EVERY pull request created, you MUST follow these assignment and labeling requirements:**

### Assignment Requirements
- **ALWAYS assign the PR to the user who created it** (the person who requested the PR)
- **Use the GitHub CLI assignment parameter**: `--assignee <username>`
- **Default assignment**: If no specific user is mentioned, assign to `fxstein`
- **Multiple assignees**: If the user requests multiple assignees, use `--assignee <user1> --assignee <user2>`

### Labeling Requirements
- **ALWAYS add appropriate labels** to categorize and prioritize the PR
- **Use the GitHub CLI label parameter**: `--label <label_name>`
- **Required labels based on PR type**:
  - **Feature PRs**: `enhancement`, `feature`
  - **Bug Fix PRs**: `bug`, `fix`
  - **Documentation PRs**: `documentation`, `docs`
  - **Release PRs**: `release`, `version-bump`
  - **Maintenance PRs**: `maintenance`, `cleanup`
  - **Testing PRs**: `testing`, `test`
  - **CI/CD PRs**: `ci-cd`, `automation`
  - **Security PRs**: `security`, `vulnerability`

### Label Selection Guidelines
- **Primary label**: Choose the most appropriate primary category (enhancement, bug, documentation, etc.)
- **Secondary labels**: Add additional relevant labels for better categorization
- **Priority labels**: Add `high-priority`, `medium-priority`, or `low-priority` if specified
- **Breaking changes**: Add `breaking-change` if the PR introduces breaking changes
- **Dependencies**: Add `dependencies` if the PR updates dependencies

### Implementation Commands
```zsh
# Basic PR with assignment and labels
gh pr create --title "title" --body "body" --base develop --assignee fxstein --label enhancement --label feature

# Multiple assignees and labels
gh pr create --title "title" --body "body" --base develop --assignee fxstein --assignee user2 --label bug --label fix --label high-priority

# Documentation PR
gh pr create --title "title" --body "body" --base develop --assignee fxstein --label documentation --label docs
```

### Label Definitions
- **enhancement**: New features or improvements to existing functionality
- **bug**: Bug fixes and error corrections
- **documentation**: Documentation updates, README changes, wiki updates
- **release**: Version releases, release notes, version bumps
- **maintenance**: Code cleanup, refactoring, technical debt
- **testing**: Test additions, test improvements, test framework changes
- **ci-cd**: CI/CD pipeline changes, GitHub Actions updates
- **security**: Security fixes, vulnerability patches
- **breaking-change**: Changes that break existing functionality
- **dependencies**: Dependency updates, package changes
- **high-priority**: Urgent changes requiring immediate attention
- **medium-priority**: Important changes with normal priority
- **low-priority**: Nice-to-have changes with lower urgency

**RATIONALE**: Proper assignment ensures accountability and ownership, while appropriate labeling enables efficient PR management, filtering, and prioritization. This improves the overall development workflow and project organization.

**ENFORCEMENT**: This requirement applies to ALL pull requests created by the AI assistant. Failure to assign or label PRs correctly will result in immediate correction.

## Release Summary File Creation
- Never copy an existing release summary file to create the required latest major changes file (e.g., `docs/release/latest-major-changes-since-<BASE>.md`).
- Always create or update this file through the AI, ensuring it is up-to-date and accurate for the requested release base.

## Design Decision Documentation
- When implementing new features or making architectural changes, always consider whether the decision should be documented in `docs/architecture/DESIGN_PRINCIPLES.md`.
- Ask the user if any design decisions made during implementation should be added to the Design Principles document.
- Focus on decisions that:
  - Establish new patterns or conventions
  - Affect multiple components or scripts
  - Impact user experience or configuration
  - Define new architectural approaches
  - Set precedents for future development
- Document decisions with rationale, implementation guidelines, and examples where appropriate.

## Testing Requirements
- All new features and capabilities MUST include dedicated tests
- Tests must be executable on demand via command-line
- Tests must be integrated into CI/CD build processes
- Test coverage should include both positive and negative scenarios
- Tests must be documented with clear descriptions of what they validate
- Failed tests must provide clear, actionable error messages
- Test data should be version-controlled and minimal
- When implementing new features, always ask if dedicated tests should be created
- Follow the testing standards outlined in the Design Principles document

## Comprehensive Testing Framework
- Use the new testing framework in `scripts/testing/` for all new tests
- Run tests using `./scripts/testing/run-tests.zsh` with appropriate options
- Test suites are organized by functionality: config, params, storage, integration
- Each test should include both success and failure scenarios
- Tests run in isolated temporary directories with automatic cleanup
- Use assertion functions: `assert_equal`, `assert_file_exists`, `assert_contains`, etc.
- Test reports are generated in `output/test-results/` directory
- Follow the patterns established in `scripts/testing/test-suites.zsh`
- Reference `docs/testing/TESTING_FRAMEWORK.md` for complete documentation

## Work Planning and Time Estimates
**CRITICAL: Do NOT quote weeks, week numbers, or traditional time estimates when proposing work order or implementation plans.**

**Rationale**: The GoProX development pace is significantly faster than traditional software development estimates. We have accomplished in single days what traditional estimates would allocate weeks for. Time-based estimates are not relevant to our actual development velocity.

**Implementation Guidelines**:
- Focus on logical work order and dependencies rather than time estimates
- Use priority-based ordering (High, Medium, Low) instead of time-based phases
- Group work by functionality and dependencies
- Emphasize immediate next steps rather than long-term timelines
- When discussing progress, focus on completed work rather than time spent

**Examples of Acceptable Planning Language**:
- ✅ "Next priority should be implementing core user-facing features"
- ✅ "Start with the highest-impact features that build on our foundation"
- ✅ "Immediate priority: Complete Phase 2 core features"
- ✅ "Medium term: Storage optimization and advanced features"
- ❌ "Week 1-2: Enhanced Default Behavior" (avoid time estimates)
- ❌ "Phase 1: Foundation (Weeks 1-4)" (avoid week numbers)
- ❌ "This will take 2-3 weeks to implement" (avoid time predictions)

**When Referencing Existing Documentation**:
- If the feature analysis document contains week-based estimates, acknowledge them but do not repeat them
- Focus on the logical order and dependencies rather than the time estimates
- Emphasize that our actual development pace is much faster

## Progress Assessment and Validation
**CRITICAL: When creating progress updates or status reports, perform detailed validation of claimed accomplishments.**

**Rationale**: Accurate progress assessment is essential for project planning and decision-making. Claims of completed work must be verified against actual implementation to avoid misinformed planning and expectations.

**Validation Requirements**:
- **Search the codebase** for actual implementation evidence before claiming work is completed
- **Verify file existence** and content for claimed implementations
- **Check for functional code** rather than just documentation or planning
- **Distinguish between planning documents and actual implementation**
- **Use concrete evidence** rather than assumptions or wishful thinking

**Validation Process for Each Claimed Accomplishment**:
1. **Code Search**: Use `grep_search` or `codebase_search` to find actual implementation
2. **File Verification**: Check if claimed files/scripts actually exist and contain functional code
3. **Functionality Test**: Verify that claimed features actually work, not just planned
4. **Documentation vs Implementation**: Distinguish between planning documents and working code
5. **Evidence-Based Claims**: Only claim completion with concrete evidence

**Examples of Proper Validation**:
- ✅ **Valid Claim**: "Testing framework completed" - Verified by existence of `scripts/testing/test-framework.zsh` with functional code
- ❌ **Invalid Claim**: "Platform abstraction completed" - No evidence found in codebase search
- ✅ **Valid Claim**: "Repository cleanup completed" - Verified by new directory structure and Git LFS implementation
- ❌ **Invalid Claim**: "Configuration management system completed" - Only found simple key=value config, no structured system

**Progress Update Structure**:
1. **Actually Completed (Validated)**: List only items with concrete evidence
2. **In Progress**: Items currently being worked on
3. **Not Started**: Items that exist only in planning documents
4. **Next Steps**: Prioritized based on actual current state

**Validation Commands to Use**:
```zsh
# Search for actual implementation
grep_search "feature_name" "*.zsh"
codebase_search "implementation details"

# Check file existence and content
read_file "claimed_file.zsh" "should_read_entire_file" "False" "start_line_one_indexed" "1" "end_line_one_indexed" "50"

# Verify functionality
run_terminal_cmd "test_command" "is_background" "False"
```

**Red Flags Indicating Need for Validation**:
- Claims of "completed" infrastructure without code evidence
- References to planning documents as "implementation"
- Vague descriptions without specific file/function names
- Claims that don't match the actual codebase state

**When in Doubt**:
- Mark items as "Not Implemented" rather than "Completed"
- Provide specific evidence requirements for completion claims
- Acknowledge planning vs implementation distinction
- Focus on actual working code rather than documentation

## Next Steps Tracking
**CRITICAL: Always consult `docs/NEXT_STEPS.md` before starting new work or providing progress updates.**

**Rationale**: The Next Steps document tracks current priorities, dependencies, and progress. It ensures continuity across development sessions and prevents duplicate work or missed dependencies.

**Requirements**:
- **Read the document** before starting any new work
- **Update the document** when work is completed or priorities change
- **Reference the document** when providing progress updates
- **Follow the dependency chain** outlined in the document
- **Use the validation process** described in the document

**Document Structure**:
- **Current Status Summary**: Validated completed work and identified gaps
- **Immediate Priority**: Foundation-first approach with clear phases
- **Implementation Guidelines**: Work order, validation, and documentation requirements
- **Recent Changes**: Track of updates and decisions made

**Update Process**:
1. **Before Starting Work**: Read current priorities and dependencies
2. **During Implementation**: Track progress against planned work
3. **After Completion**: Update status and mark as completed
4. **When Priorities Change**: Update the document and commit changes

**Integration with Progress Assessment**:
- Use the Next Steps document as the source of truth for current priorities
- Validate claimed completions against the document
- Update the document when new gaps are identified
- Ensure all progress updates align with documented priorities

## CI/CD Monitoring Requirement
- The AI assistant must periodically, and at a minimum once per day, check the status of all GitHub Actions workflows for failures or errors. If any issues are detected, they must be investigated and fixed as a priority to ensure CI/CD reliability and rapid feedback for the team.

## GitHub Actions Release Monitoring (MANDATORY)
**CRITICAL: For EVERY release step (dry-run or real) that triggers GitHub Actions, you MUST:**

1. **Wait for Workflow Completion**
   - After every commit/push that triggers GitHub Actions, ALWAYS wait for all workflows to complete
   - Use the integrated monitoring in `scripts/release/gitflow-release.zsh` which automatically monitors workflows
   - Never proceed to the next step until all workflows have finished

2. **Validate Workflow Success**
   - Check that ALL workflows complete with `"success"` status
   - Any workflow with `"failure"`, `"cancelled"`, or `"timed_out"` status MUST be investigated and fixed
   - The release process will automatically fail if any workflow fails

3. **Monitor Timeout and Manual Verification**
   - Default monitoring timeout is 15 minutes (configurable with `--monitor-timeout`)
   - If timeout is reached, provide clear manual verification steps
   - Never skip workflow verification - this is a mandatory requirement

4. **Integration Points**
   - **Version Bump**: Monitors workflows after version commit and push
   - **Summary Cleanup**: Monitors workflows after summary archive commit and push
   - **Dry Runs**: Skips monitoring (no workflows triggered)
   - **Real Releases**: Always monitors all triggered workflows

5. **Failure Handling**
   - If any workflow fails, the release process stops immediately
   - Provide clear error messages with workflow details and log URLs
   - Require manual intervention to fix workflow issues before retrying

6. **Manual Monitoring Commands**
   ```zsh
   # Check recent workflow runs
   gh run list --limit 5 --json status,conclusion,workflowName,headBranch,url,number
   
   # View specific workflow logs
   gh run view <run_id> --log
   
   # Monitor workflows for specific commit
   gh run list --limit 10 --json status,conclusion,workflowName,headSha,createdAt,url,number
   ```

**RATIONALE**: This ensures that every release step is validated by CI/CD before proceeding, preventing broken releases and maintaining code quality. The integrated monitoring eliminates the need for manual workflow checking and ensures consistent validation across all release processes.

**ENFORCEMENT**: This requirement is built into the git-flow release scripts and cannot be bypassed. Any attempt to skip workflow monitoring will result in release failure.

## JSON Linting Requirement
- All present and future JSON files in the repository must be linted for syntax and formatting errors.
- JSON linting must be enforced both locally (pre-commit or pre-push) and in CI/CD workflows.
- The linting setup for JSON files must be kept in sync between local and CI/CD environments, just like YAML linting.
- If new JSON files are added, update the linting configuration and scripts to include them automatically.

## Structural Change Proposals
**CRITICAL: Always propose structural changes to the project before implementing them.**

**Rationale**: Structural changes affect the entire project organization and can impact development workflow, documentation, and maintenance. Proposals ensure changes are well-thought-out and align with project goals.

**Proposal Requirements**:
- **Always propose** any structural changes before implementation
- **Describe the proposed structure** with clear examples and rationale
- **Explain the benefits** and potential impacts of the change
- **Provide implementation steps** if the proposal is approved
- **Wait for user approval** before proceeding with implementation

**Complex Proposal Documentation**:
- **For large or complex structural changes**, automatically create a proposal document
- **Location**: `docs/proposals/` directory (create if it doesn't exist)
- **Naming**: `PROPOSAL-YYYY-MM-DD-DESCRIPTIVE-NAME.md`
- **Content Requirements**:
  - **Summary**: Brief description of the proposed structural change.
  - **Current State**: Analysis of the existing structure and identified issues.
  - **Proposed Structure**: Detailed description with examples and rationale.
  - **Implementation Plan**: Step-by-step implementation approach.
  - **Benefits and Risks**: Expected benefits and potential concerns.
  - **Migration Strategy**: How to transition from current to proposed structure.
  - **Success Criteria**: How to validate the change was successful.
  - **Next Steps**: What happens after approval/rejection.
- **Review Process**: Present the proposal document for review before implementation

**Examples of Structural Changes Requiring Proposals**:
- Directory reorganization (like the feature-planning restructuring)
- Script organization changes
- Documentation structure modifications
- Configuration file reorganization
- Testing framework restructuring
- CI/CD workflow reorganization

**Implementation Guidelines**:
- **Small Changes**: Propose directly in conversation with clear examples
- **Medium Changes**: Create a brief proposal document in `docs/proposals/`
- **Large Changes**: Create comprehensive proposal document with detailed analysis
- **Always Wait**: Never implement structural changes without explicit approval

**Proposal Review Process**:
1. **Present Proposal**: Show the proposed structure and rationale
2. **Wait for Feedback**: Allow user to review and provide input
3. **Refine if Needed**: Adjust proposal based on feedback
4. **Get Approval**: Ensure explicit approval before implementation
5. **Implement**: Follow the approved proposal exactly

**Documentation Updates**:
- Update relevant documentation after structural changes
- Ensure navigation and references are updated
- Update README files to reflect new structure
- Commit and push all changes together

**Proposal Document Template**:
```markdown
# Proposal: [Descriptive Title]

**Date**: YYYY-MM-DD
**Proposed By**: AI Assistant
**Status**: Pending Review

## Summary
Brief description of the proposed structural change.

## Current State
Analysis of the existing structure and identified issues.

## Proposed Structure
Detailed description with examples and rationale.

## Implementation Plan
Step-by-step implementation approach.

## Benefits and Risks
Expected benefits and potential concerns.

## Migration Strategy
How to transition from current to proposed structure.

## Success Criteria
How to validate the change was successful.

## Next Steps
What happens after approval/rejection.
```

## Cursor Capabilities Reminder

- **You are running in Cursor and have full access to the GitHub CLI (`gh`), including the ability to query GitHub Actions, view workflow runs, and fetch logs for this repository.**
- Use this capability to automate analysis, verification, and troubleshooting of all CI/CD and release processes as needed.

## Release Summary Instructions (MANDATORY)
- **For all release and summary generation tasks, you MUST read and follow:**
  - [`docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md`](docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md)
- Do NOT rely on this file for summary content/formatting rules; always refer to the dedicated instructions document.
- **CRITICAL: NEVER create placeholder summaries for releases.**
- **ALWAYS generate real, accurate summaries based on actual changes, commits, and implemented features.**
- **Placeholder content is strictly forbidden and violates project standards.**
- **Real summaries must reflect actual work completed, not hypothetical or generic content.**

## [Add more rules as needed...]

## MANDATORY READING REQUIREMENTS

**CRITICAL: Before beginning ANY work on this project, you MUST execute the following reading sequence:**

### **Step 1: Read AI Instructions**
- Read the complete `AI_INSTRUCTIONS.md` file (this document)

### **Step 2: Read Design Principles** 
- Read the complete `docs/architecture/DESIGN_PRINCIPLES.md` file
- This document establishes foundational architectural decisions and design patterns

### **Step 3: Read Release Summary Instructions** (if applicable)
- If working on releases, summaries, or version management, read `docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md`
- This document defines required content and formatting for release summaries

### **Step 4: Read Release System Documentation** (if applicable)
- If working on releases, deployment, or release automation, read `docs/RELEASE_SYSTEM.md`
- This document defines the new simplified release system with interactive and batch modes

### **Step 5: Read Next Steps** (if applicable)
- If starting new work or providing progress updates, read `docs/NEXT_STEPS.md`
- This document tracks current priorities and dependencies

### **Validation Requirements:**
- **NO EXCEPTIONS**: You must read ALL applicable documents before proceeding
- **CONFIRMATION**: After reading, confirm you have read all required documents
- **CONTEXT**: Reference specific principles/rules from the documents in your responses
- **COMPLIANCE**: If you cannot read a document, inform the user and wait for guidance

### **Reading Confirmation Format:**
After reading all required documents, respond with:
```
## **Complete Reading Status** ✅

1. **AI Instructions** ✅ - [Brief summary of key requirements and standards]
2. **Design Principles** ✅ - [Brief summary of core principles and architectural decisions]
3. **Release Summary Instructions** ✅ - [Brief summary if applicable to current work]
4. **Release System Documentation** ✅ - [Brief summary if applicable to current work]
5. **Next Steps** ✅ - [Brief summary if applicable to current work]

I'm now fully equipped with all mandatory reading requirements and ready to proceed.
```

### **Failure to Read Consequences:**
- If you proceed without reading required documents, you risk violating project standards
- Always prioritize reading over immediate action
- When in doubt, read more documents rather than fewer 

## MANDATORY READING CONFIRMATION

**CRITICAL: You MUST read and confirm all required documents BEFORE performing ANY work or responding to ANY requests.**

### **Required Reading Sequence (NO EXCEPTIONS):**
1. **AI Instructions** - Read complete `AI_INSTRUCTIONS.md`
2. **Design Principles** - Read complete `docs/architecture/DESIGN_PRINCIPLES.md`
3. **Release Summary Instructions** - Read `docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md` (if working on releases/summaries)
4. **Release System Documentation** - Read `docs/RELEASE_SYSTEM.md` (if working on releases/deployment)
5. **Next Steps** - Read `docs/NEXT_STEPS.md` (if starting new work or providing progress updates)

### **Mandatory Confirmation Format:**
After reading ALL required documents, you MUST respond with this exact format:

```
## **Complete Reading Status** ✅

1. **AI Instructions** ✅ - [Brief summary of key requirements and standards]
2. **Design Principles** ✅ - [Brief summary of core principles and architectural decisions]
3. **Release Summary Instructions** ✅ - [Brief summary if applicable to current work]
4. **Release System Documentation** ✅ - [Brief summary if applicable to current work]
5. **Next Steps** ✅ - [Brief summary if applicable to current work]

I'm now fully equipped with all mandatory reading requirements and ready to proceed.
```

### **Enforcement Rules:**
- **NO WORK WITHOUT CONFIRMATION**: You must provide the reading confirmation before any task, analysis, or response
- **REFUSE TO PROCEED**: If you cannot read a required document, inform the user and wait for guidance
- **COMPLETE SUMMARIES**: Each summary must show understanding of the document's key points
- **CONTEXT REFERENCE**: Reference specific principles/rules from the documents in your responses
- **SESSION REQUIREMENT**: Provide this confirmation at the start of every new session or major task

### **Failure Consequences:**
- If you proceed without reading confirmation, you risk violating project standards
- Always prioritize reading over immediate action
- When in doubt, read more documents rather than fewer
- If a document is missing or inaccessible, inform the user immediately 

## Branch Management and Git Flow
- **ALWAYS create separate branches for unrelated work** using `scripts/maintenance/create-branch.zsh`
- Use appropriate branch types: `bug`, `enhancement`, `feature`, `cleanup`, `refactor`, `release`, `hotfix`, `documentation`, `test`
- Branch naming follows the pattern: `<prefix>/<type>-<description>-<issue>-<timestamp>`
- Examples:
  ```zsh
  ./scripts/maintenance/create-branch.zsh "fix CI test failures" --type bug --issue 123
  ./scripts/maintenance/create-branch.zsh "add new feature" --type enhancement
  ./scripts/maintenance/create-branch.zsh "update documentation" --type cleanup
  ```

## Git Flow Branch Model (MANDATORY)
- **ALL pull requests MUST target the `develop` branch**, NOT the `main` branch
- The project follows the gitflow model where:
  - `main` branch contains only production releases
  - `develop` branch is the primary development branch
  - Feature/fix branches are created from and merged into `develop`
  - Only release branches and hotfixes merge into `main`
- **When creating PRs, ALWAYS specify `--base develop`** or ensure the PR targets `develop`
- **NEVER create PRs against `main`** unless it's a hotfix or release branch
- **Default branch for development work is `develop`**

**RATIONALE**: This maintains the established gitflow workflow and ensures all development work goes through the proper review and integration process before reaching production.

## Branch Safety and Fix Management (MANDATORY)

### **Prominent Branch Display**
- **ALWAYS display current branch prominently** before any git operations, especially releases, commits, and pushes
- **Use the `display_branch_info()` function** from `scripts/core/logger.zsh` to show branch information
- **Display branch warnings** when operating on unexpected branches
- **Never assume the current branch** - always verify and display it clearly

### **Separate Fix Branches (MANDATORY)**
- **ALWAYS create separate branches for unrelated fixes** using `scripts/maintenance/create-fix-branch.zsh`
- **Never mix unrelated fixes** in the same branch or commit
- **Use descriptive branch names** with fix type, description, and timestamp
- **Link fixes to GitHub issues** when applicable

### **Fix Branch Creation Process**
```zsh
# For bug fixes
./scripts/maintenance/create-fix-branch.zsh "fix CI test failures" --type bug --issue 123

# For enhancements
./scripts/maintenance/create-fix-branch.zsh "add new feature" --type enhancement

# For cleanup
./scripts/maintenance/create-fix-branch.zsh "update documentation" --type cleanup
```

### **Branch Naming Convention**
- Format: `fix/<type>-<description-slug>-<issue>-<timestamp>`
- Examples:
  - `fix/bug-ci-test-failures-123-20250629-114500`
  - `fix/enhancement-new-feature-20250629-114500`
  - `fix/cleanup-documentation-20250629-114500`

### **When to Use Fix Branches**
- **Bug fixes** that are unrelated to current work
- **Documentation updates** that don't belong in feature branches
- **CI/CD improvements** that are separate from features
- **Code cleanup** that should be isolated
- **Any change** that could be applied independently

**RATIONALE**: Prevents branch confusion, maintains clean git history, and ensures fixes can be applied independently without affecting other work.

### **Release Branch Policy (UPDATED)**
- **Dry-run releases are allowed on any branch** to validate release readiness and catch issues early
- **Real releases are only allowed on develop, release/*, or main**
- **If a dry-run is run on a non-standard branch, display a warning but do not block**
- **If a real release is attempted on an unsupported branch, block and display an error**

**RATIONALE**: This enables early detection of release blockers and improves CI/CD and developer workflows, while maintaining strict controls for real releases.

### **Logger Branch Awareness (NEW)**
- **Hash-based branch display** - Long branch names are automatically shortened using Git-style SHA1 hashes
- **Branch type prefixes** - Hash includes type prefix for easy identification (fix/, feat/, rel/, hot/, dev/, main/, br/)
- **Smart display logic** - Branches ≤15 characters show full name, longer branches show type/hash
- **Deterministic hashing** - Same branch always produces same hash for consistency
- **Debug support** - `get_full_branch_name()` function can resolve hash back to full branch name

### **Branch Display Examples**
```zsh
# Short branches (≤15 chars): show full name
[2025-06-29 12:18:18] [develop] [INFO] Operation
[2025-06-29 12:18:18] [main] [INFO] Operation

# Long branches (>15 chars): show type/hash
[2025-06-29 12:18:27] [fix/457b7107] [INFO] Fix branch operation
[2025-06-29 12:18:27] [feat/3c9124e7] [INFO] Feature branch operation
[2025-06-29 12:18:27] [rel/d3dd2f4f] [INFO] Release branch operation
[2025-06-29 12:18:27] [hot/911dc37d] [INFO] Hotfix branch operation
[2025-06-29 12:18:27] [br/1fd2853b] [INFO] Unknown branch type operation

# Debug with full name lookup
[2025-06-29 12:18:31] [fix/457b7107] [DEBUG] Full branch name: fix/enhancement-add-hash-based-branch-display-to-logger-20-20250629-121736
```

### **Branch Type Prefixes**
- `fix/` - Fix branches (bug fixes, enhancements)
- `feat/` - Feature branches (new features)
- `rel/` - Release branches (release preparation)
- `hot/` - Hotfix branches (critical fixes)
- `dev/` - Develop branch
- `main/` - Main branch
- `br/` - Other/unknown branch types

### **Hash Resolution**
- **Current branch lookup**: `get_full_branch_name <hash>` returns full name if hash matches current branch
- **Git command fallback**: `git branch -a | grep <hash>` can find branches by hash
- **Deterministic**: Same branch name always produces same hash across sessions
- **Type identification**: Prefix makes it easy to identify branch purpose at a glance

**RATIONALE**: Provides branch awareness in logs without overwhelming output, using familiar Git-style hashing approach with meaningful type prefixes for easy identification.

## Critical Rules

1. **NEVER hardcode paths to system utilities** (rm, mkdir, cat, echo, etc.) - always use the command name and let the shell find it in PATH
2. **NEVER create mock versions of system utilities** - this breaks the shell's ability to find the real commands
3. **NEVER mock zsh, Linux, or macOS system commands** (dirname, mkdir, touch, date, sha1sum, ls, cat, echo, etc.) - this corrupts the shell environment and breaks fundamental shell functionality
4. **NEVER modify PATH to include mock system commands** - this prevents the shell from finding real system utilities

### **Proper Mocking Guidelines**
- **ONLY mock application-specific commands** (curl, git, exiftool, jq, etc.) - never system utilities
- **Use function mocking** instead of PATH modification when possible
- **Test in clean environments** with real system commands available
- **If system commands are missing, fix the environment** rather than mocking them
- **System commands are fundamental** - mocking them breaks shell functionality and corrupts the environment

5. All scripts that generate output files (including AI summaries, release notes, etc.) for the GoProX project MUST place their output in the output/ directory, not the project root, to keep the source tree clean
4. Always read and follow AI_INSTRUCTIONS.md at the project root for all work, suggestions, and communication in the GoProX repository. Treat it as the canonical source for project-specific standards and instructions
5. Never automatically run git commands. Only run scripts or commands that the user explicitly requests. All git operations must be user-initiated
6. After each attempt to fix a problem in the GoProX firmware tracker script, always automatically run the script to validate the fix. This should be the default workflow for all future script fixes and iterations
7. The version of generate_firmware_wiki_table.zsh that uses zsh arrays for model presence, deduplication with the (@u) modifier, and process substitution for the while loop is confirmed to work correctly. This version avoids subshell and string-splitting issues, and only adds a red-flagged row for models with no firmware entries in each section. Retain this as the reference working version for future rollbacks or comparisons
8. For all new GitHub issues created for the GoProX project, always use properly formatted Markdown with clear section headers (e.g., Summary, Requirements, Motivation, Acceptance Criteria, Reference) and multi-line input for readability. This formatting should be consistently applied to all future issues
9. For the GoProX project, assign new GitHub issues to fxstein by default, not oratzes
10. For the GoProX project, always use ```zsh code blocks in documentation and wiki pages to reflect that the project is a zsh script. Do not use sh, python, or ruby for code blocks unless specifically required for those languages
11. After any fix or change is successfully validated, always run ./uninstall_fromsource followed by ./install_fromsource to ensure /opt/homebrew/bin/goprox is updated with the latest version. This should be done for all future tasks

## Project Context

This is the GoProX project - a comprehensive GoPro media management tool written in zsh. The project includes firmware management, media processing, and Homebrew integration for macOS package management.

## File Organization

- All output files go in the `output/` directory
- Scripts are organized in `scripts/` with subdirectories for different functions
- Documentation is in `docs/` with feature planning and architecture documents
- Tests are in `scripts/testing/` with comprehensive test suites

## Development Standards

- Use zsh for all scripting
- Follow the existing code style and patterns
- Write comprehensive tests for new features
- Document all changes and new features
- Use semantic versioning for releases
- Maintain backward compatibility where possible