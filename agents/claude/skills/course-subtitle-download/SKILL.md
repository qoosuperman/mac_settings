---
name: course-subtitle-download
description: 下載 Hahow 2C 課程所有影片單元的字幕，整理成給 AI 分析用的逐字稿（transcript.md）並保留原始 SRT。當使用者給課程 id 並說「下載字幕」「抓課程逐字稿」「把這門課的字幕都載下來」「我要分析這門課的內容」時使用。透過 PADA 後台（需 VPN）與 claude-in-chrome 取得單元清單。不適用於上傳或編修字幕、下載影片檔，或 Hahow for Business 企業自建課程。
---

# 下載課程字幕

給一個課程 id，產出 `~/Downloads/hahow-subtitles/<課程id>_<課程名稱>/`：

- `transcript.md`：去除時間軸、依章節與單元排列的逐字稿，給 AI 摘要或分析用
- `raw/<單元編號>_<單元名稱>.srt`：原始字幕備份

字幕連結 `https://hahow.in/subtitles/<id>?format=srt` 不需登入，只有取得單元清單需要 PADA，所以瀏覽器只用來讀清單，下載交給 script。

## 步驟

1. 這個 skill 使用 claude-in-chrome（使用者指定，不用 gstack `/browse`）。用 ToolSearch 一次載入 `tabs_context_mcp`、`tabs_create_mcp`、`navigate`、`computer`、`javascript_tool`。
   - 回報 extension 未連線：請使用者在 Claude Code 執行 `/chrome` 重新連線。
2. 呼叫 `tabs_context_mcp`（`createIfEmpty: true`），在分頁群組中前往 `https://pada.hahow.in/courses?_id=<課程id>`。
   - PADA 載入時會先短暫顯示登入表單，等登入狀態確認後才出現課程列表。先 `computer` 截圖確認，看到登入表單就等幾秒再截一次。
   - 等待後仍是登入表單：請使用者在這個分頁登入 PADA（不可代為輸入帳密），登入後重新前往同一網址。
   - 頁面無法載入或逾時：多半是沒連 VPN，請使用者連上後重試。
   - 課程表格沒有資料：回報課程 id 可能有誤。
3. 用 `javascript_tool` 執行下方「收集單元清單」的 JS。它會點開「單元影片下載」彈窗（不是「單元列表」，那個彈窗沒有字幕欄位）、把 manifest 存在 `window.__subtitleManifest`，並回傳摘要。
   - JS 會先把每個表格的每頁筆數設為 100。`multiPage` 仍不是空陣列代表該章節超過 100 個單元，告知使用者這些章節的清單不完整。
   - `skipped` 列出沒有 srt 字幕的單元（通常是作業），回報時一併告知使用者。
4. 分段讀出 manifest：`javascript_tool` 的回傳超過約 1000 字元會被截斷，所以依摘要的 `length`，以每段 900 字元執行
   `window.__subtitleManifest.slice(0, 900)`、`slice(900, 1800)`……直到讀完。
   把各段原樣依序接起來，寫到 scratchpad 的 `manifest-<課程id>.json`。
5. 驗證並執行（`<skill 目錄>` 為這份 SKILL.md 所在目錄）：
   ```bash
   python3 -c "import json,sys; raw=open(sys.argv[1],encoding='utf-8').read().rstrip('\n'); m=json.loads(raw); print(len(raw), sum(len(c['units']) for c in m['chapters']))" <manifest 路徑>
   python3 <skill 目錄>/scripts/download_subtitles.py <manifest 路徑>
   ```
   第一行印出的長度與單元數要等於摘要的 `length` 與 `units`；不一致代表接段時出錯，重讀 manifest。
6. 回報輸出目錄、成功與失敗的單元數、略過的單元；有失敗單元時列出編號。完成後用 `tabs_close_mcp` 關掉自己開的分頁。

## 收集單元清單的 JS

```js
await (async () => {
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  document.querySelector('.modal.show .close')?.click();
  await sleep(500);
  const openButton = [...document.querySelectorAll('button, a')].find((el) => el.textContent.trim() === '單元影片下載');
  if (!openButton) return JSON.stringify({ error: '找不到「單元影片下載」按鈕' });
  openButton.click();
  await sleep(3000);

  // 表格預設每頁 20 筆，單元多的章節會分頁；ReactTable 的 select 需用原生 setter 才會觸發 onChange
  const valueSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value').set;
  for (const select of document.querySelectorAll('.modal.show .-pagination select')) {
    valueSetter.call(select, '100');
    select.dispatchEvent(new Event('change', { bubbles: true }));
  }
  await sleep(1000);

  const modal = document.querySelector('.modal.show');
  const courseTitle = modal.querySelector('.modal-title').textContent.trim().replace(/^單元列表（(.*)）$/, '$1');
  const courseId = new URLSearchParams(location.search).get('_id');
  const chapters = [];
  const skipped = [];
  const multiPage = [];
  for (const heading of modal.querySelectorAll('.modal-body > h3')) {
    const [, number, title] = heading.textContent.trim().match(/^(\S+)\s*-\s*(.+)$/);
    const chapter = { number, title, units: [] };
    let table = heading.nextElementSibling;
    while (table && !table.classList.contains('ReactTable') && table.tagName !== 'H3') table = table.nextElementSibling;
    if (table?.classList.contains('ReactTable')) {
      if (Number(table.querySelector('.-totalPages')?.textContent ?? 1) > 1) multiPage.push(number);
      const headers = [...table.querySelectorAll('.rt-thead .rt-th')].map((th) => th.textContent.trim());
      const nameIndex = headers.indexOf('單元名稱');
      const subtitleIndex = headers.indexOf('字幕下載');
      for (const row of table.querySelectorAll('.rt-tbody .rt-tr-group')) {
        const cells = row.querySelectorAll('.rt-td');
        const name = cells[nameIndex]?.textContent.trim() ?? '';
        if (!name) continue;
        const srtLink = [...cells[subtitleIndex].querySelectorAll('a')]
          .find((link) => link.textContent.trim().endsWith('(srt)'));
        const match = name.match(/單元\s*([\d-]+)\s*[:：]\s*(.+)$/);
        if (!srtLink || !match) { skipped.push(name); continue; }
        const subtitleId = new URL(srtLink.href).pathname.split('/').pop();
        chapter.units.push({
          number: match[1],
          title: match[2].trim(),
          srt_url: `https://hahow.in/subtitles/${subtitleId}?format=srt`,
        });
      }
    }
    chapters.push(chapter);
  }
  // emoji 等 BMP 以外的字元轉成 \uXXXX，讓 JS 與 Python 的長度一致，分段時也不會切斷字元
  window.__subtitleManifest = JSON.stringify({ course_id: courseId, course_title: courseTitle, chapters })
    .replace(/[\u{10000}-\u{10FFFF}]/gu, (char) => char.split('')
      .map((unit) => `\\u${unit.charCodeAt(0).toString(16).padStart(4, '0')}`).join(''));
  return JSON.stringify({
    length: window.__subtitleManifest.length,
    units: chapters.reduce((sum, chapter) => sum + chapter.units.length, 0),
    chapters: chapters.map((chapter) => `${chapter.number}:${chapter.units.length}`),
    skipped,
    multiPage,
  });
})()
```

彈窗結構（PADA 改版時對照用）：章節為 `.modal-body > h3`（「1 - 章節名稱」），其後的 `.ReactTable` 是該章單元；
「單元名稱」欄為「[影片] 單元 1-1：  課程介紹」，畫面上以 CSS 截斷但 `textContent` 是完整名稱；
「字幕下載」欄有 `zh-TW`（VTT）與 `zh-TW (srt)` 兩個連結。

若 JS 拋錯、回傳 `error`，或單元數明顯不對，代表 PADA 畫面改版：用 `read_page` 查看彈窗結構，調整選擇器後重跑，並告知使用者 SKILL.md 需要更新。
