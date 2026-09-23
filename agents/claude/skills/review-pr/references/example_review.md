# Worked Example (illustrative)

Illustrative output for a hypothetical PR `acme/shop#482` ("Add coupon expiry check").
Replace with a real review output once one is collected.

```markdown
## Summary

- **What**: Rejects expired coupons at checkout and adds an `expires_at` column to `coupons`.
- **Author**: @dev-a
- **Scope**: 6 files changed, +148 / -22

## Findings

### Critical (blocks merge)
- [app/services/checkout.rb:57] Expiry is compared with `Date.today` while `expires_at` is a UTC datetime — failure scenario: coupon expiring 2026-09-23T15:00Z, user checks out at 2026-09-23T20:00Z → `expires_at.to_date >= Date.today` is true, expired coupon is accepted.

### Major (should fix before merge)
- [db/migrate/20260920_add_expires_at_to_coupons.rb:3] `add_column ... null: false` without a default on an existing table — failure scenario: migration runs on production with existing rows → migration fails. Violates `.claude/rules/migrations.md`: "New NOT NULL columns must ship with a default or a backfill step."

### Minor / Suggestions
- [spec/services/checkout_spec.rb:88] Add a case for a coupon expiring exactly at checkout time.

## PR Checklist

- [ ] Tests cover changed behavior — boundary case missing
- [x] No security concerns (injection, auth, secrets)
- [x] No breaking API/interface changes (or documented)
- [ ] Error handling for edge cases — timezone boundary
- [ ] Complies with project rules (CLAUDE.md / .claude/rules/) — migration rule

## Merge Recommendation

⛔ Blocked — expired coupons can be accepted (checkout.rb:57), and the migration fails on non-empty tables.
```

Notes on what was intentionally left out:
- A reviewer comment already flagged the missing index on `expires_at`; not re-raised.
- RuboCop line-length warnings in `checkout.rb`: CI catches them.
