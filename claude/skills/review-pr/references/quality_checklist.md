# review-pr Quality Checklist

Last updated: 2026-04-01

## Format

- [x] Frontmatter keys are all in allowed set
- [x] No angle brackets in YAML frontmatter values
- [x] `name` matches folder name
- [x] `description` is present and non-empty
- [x] `allowed-tools` is present

## Requirements / Spec

- [x] Description contains trigger phrases
- [x] Description contains negative triggers (not-for)
- [x] Description describes output deliverable
- [x] Follow-through policy defined (auto / ask / never)
- [x] Output contract specifies sections, order, and done condition
- [x] Prerequisites / failure handling documented
- [ ] Few-shot worked example included

## Common Errors

- [x] No overlap conflict with neighboring skills (codex-cli-review, /review)
- [x] No forbidden frontmatter keys
- [x] No unreferenced files in skill folder

## Readiness Gate

**Status: CONDITIONAL PASS**

Remaining item:
- Few-shot worked example: not yet added. Acceptable for initial release but should be added after collecting 1-2 real review outputs.
