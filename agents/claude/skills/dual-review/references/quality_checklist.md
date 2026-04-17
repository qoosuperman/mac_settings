# Quality Checklist — dual-review

## Format

- [x] Frontmatter: name, description, allowed-tools 齊全
- [x] Description 包含 trigger phrases、何時用、何時不用、成功輸出
- [x] Output contract 有明確段落順序與完成條件
- [x] Follow-through policy 分三級

## Requirements

- [x] 支援 PR mode（PR URL / number）
- [x] 支援 Local mode（uncommitted changes）
- [x] 支援 Branch mode（--base）
- [x] 兩個 subagent 平行啟動
- [x] 整合報告包含 Agreement / Divergence / Action Items
- [x] Arguments 表格與 examples 齊全

## Common Errors

- [ ] 驗證：PR mode 時兩個 subagent 都能正確拿到 diff
- [ ] 驗證：codex CLI 不可用時 fallback 正常運作
- [ ] 驗證：Local mode 時 review-pr subagent 不會嘗試呼叫 `gh pr`
- [ ] 驗證：大型 diff 不會超出 subagent context

## Neighbor Overlap

- `review-pr`: 單獨 PR review，dual-review 是它的超集
- `codex-cli-review`: 單獨 codex review，dual-review 是它的超集
- `review`: pre-landing diff review（不同用途，不衝突）

## PASS / FAIL

- **Status**: PASS (structure ready, pending functional testing)
