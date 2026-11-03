---
name: course-preview-url
description: 把 Hahow 課程 id 轉成課程預覽網址（https://hahow.in/classroom/<id>/main?mode=preview）。當使用者貼上一個或多個課程 id（24 字元的 hex 字串，例如 68186cab7b691d6899006945），並說「preview 網址」「預覽連結」「產生課程連結」或只是丟一串 id 要網址時使用。不適用於需要查詢資料庫確認課程是否存在，或要產生非 preview 模式網址的情境。
---

# 課程 Preview 網址

把每個課程 id 套進下列格式：

```
https://hahow.in/classroom/<id>/main?mode=preview
```

範例：`68186cab7b691d6899006945` → `https://hahow.in/classroom/68186cab7b691d6899006945/main?mode=preview`

## 輸入

- 使用者可能一次給多個 id，分隔方式不固定（換行、空白、逗號、混在一段文字裡），逐一取出。
- 去除 id 前後的空白、引號與標點。
- 課程 id 通常是 24 字元的 hex 字串（MongoDB ObjectId）。不符合這個格式的仍照樣產生網址，但在輸出後補一行提醒哪些 id 格式看起來不對，讓使用者自行確認。

## 輸出

依輸入順序每行一個網址，放在 code block 裡方便直接複製，不加額外說明：

```
https://hahow.in/classroom/68186cab7b691d6899006945/main?mode=preview
```
