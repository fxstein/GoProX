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
   - Always use `scripts/release/full-release.zsh` for releases
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

## Release Workflow Automation

- When the user requests a release, always use the `./scripts/release/full-release.zsh` script to perform the entire release process (version bump, workflow trigger, monitoring) in a single, automated step.
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

### **Step 4: Read Next Steps** (if applicable)
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
4. **Next Steps** ✅ - [Brief summary if applicable to current work]

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
4. **Next Steps** - Read `docs/NEXT_STEPS.md` (if starting new work or providing progress updates)

### **Mandatory Confirmation Format:**
After reading ALL required documents, you MUST respond with this exact format:

```
## **Complete Reading Status** ✅

1. **AI Instructions** ✅ - [Brief summary of key requirements and standards]
2. **Design Principles** ✅ - [Brief summary of core principles and architectural decisions]
3. **Release Summary Instructions** ✅ - [Brief summary if applicable to current work]
4. **Next Steps** ✅ - [Brief summary if applicable to current work]

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