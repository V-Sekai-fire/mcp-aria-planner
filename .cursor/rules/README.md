# Cursor Rules Organization

This directory contains workspace-level rules that guide development practices, coding standards, and communication style for the aria-planner project.

## Directory Structure

Rules are organized into the following categories:

### `/commit/` - Commit Message Rules
Guidelines for writing commit messages:
- `commit-message-style.mdc` - General style requirements (no conventional commits)
- `commit-message-completeness-check.mdc` - Mandatory completeness verification
- `telegraph-style-commit-messages.mdc` - Implementation detail for concise messaging

### `/testing/` - Testing Philosophy
Testing approaches and best practices:
- `sociable-unit-testing.mdc` - Prefer sociable over solitary tests
- `callsite-to-nested-testing.mdc` - Testing patterns
- `pytest-bug-fix-system.mdc` - Bug fix testing workflow

### `/architecture/` - Architectural Principles
Design principles and patterns:
- `walking-skeleton.mdc` - Minimal end-to-end implementation pattern
- `problem-first-approach.mdc` - Document problems before solutions
- `simple-solutions-for-simple-problems.mdc` - Match solution complexity to problem
- `targeted-solutions-over-generalized-systems.mdc` - Single responsibility principle
- `postgresql-etnf-design.mdc` - Database design patterns

### `/communication/` - Communication Style
Tone and style guidelines:
- `communication-preferences-and-style.mdc` - General communication guidelines
- `audience-and-tone.mdc` - Target audience considerations
- `professional-and-timeless-language.mdc` - Language standards
- `aria-vtuber-personality-traits.mdc` - Aria's personality characteristics

### `/elixir/` - Elixir-Specific Rules
Language-specific guidelines:
- `elixir-module-splitting.mdc` - When and how to split modules
- `elixir-app-readme.mdc` - App documentation standards

### `/process/` - Process and Workflow
Development processes and workflows:
- `process-adrs.mdc` - Architecture Decision Record process
- `adr-style-guide.mdc` - ADR format requirements (< 50 lines)
- `discuss-solutions-before-implementation.mdc` - Collaboration requirements
- `single-fix-principle.mdc` - One fix per change
- `logical-commit-grouping.mdc` - Commit organization
- `umbrella-project-workflow-enforcement.mdc` - Umbrella project guidelines
- And more workflow-related rules...

## Rule Types

Rules are marked with metadata at the top:
- `type: Always` - Rules that are always applied
- Other types may be defined for conditional application

## Cross-References

Rules may reference each other using relative paths:
- `commit-message-style.mdc` references `telegraph-style-commit-messages.mdc`

When referencing rules, use the filename (e.g., `telegraph-style-commit-messages.mdc`) rather than ADR IDs or other identifiers.

## Adding New Rules

1. **Choose the appropriate category** based on the rule's focus
2. **Use descriptive filenames** with kebab-case (e.g., `my-new-rule.mdc`)
3. **Include metadata** at the top with `type: Always` and a description
4. **Cross-reference** related rules using filenames
5. **Follow existing patterns** for consistency

## Key Principles

- **Problem-first**: Document problems before proposing solutions
- **Simple solutions**: Match solution complexity to problem complexity
- **Single responsibility**: Each rule file has one clear purpose
- **Natural communication**: Avoid conventional commit prefixes, use telegraph style
- **Sociable testing**: Prefer real dependencies over mocks when possible

