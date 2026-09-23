# review-pr Quality Checklist

Last updated: 2026-09-23

## Format

- [x] Frontmatter keys are all in allowed set
- [x] No angle brackets in YAML frontmatter values
- [x] `name` matches folder name
- [x] `description` is present and non-empty
- [x] `allowed-tools` is present and scoped to read-only `gh` subcommands (no `Edit`)

## Requirements / Spec

- [x] Description contains trigger phrases
- [x] Description contains negative triggers (not-for)
- [x] Description describes output deliverable
- [x] Follow-through policy defined (auto / ask / never), consistent with allowed-tools and Notes
- [x] Output contract specifies sections, order, and done condition
- [x] Prerequisites / failure handling documented
- [x] False-positive exclusion list and finding verification step defined
- [x] Rule-compliance check against CLAUDE.md / .claude/rules/
- [x] Posting comments procedure documented (ask first)
- [~] Few-shot worked example included (`references/example_review.md`, illustrative; replace with a real output)

## Common Errors

- [x] No overlap conflict with neighboring skills (codex-cli-review, /review)
- [x] No forbidden frontmatter keys
- [x] No unreferenced files in skill folder
- [x] Headings referenced by dual-review kept: `Follow-Through Policy`, `Determine the PR`, `Output Contract`

## Readiness Gate

**Status: PASS (pending real example)**

Remaining item:
- Replace the illustrative example with a real review output.
