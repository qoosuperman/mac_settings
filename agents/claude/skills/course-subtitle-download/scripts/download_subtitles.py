#!/usr/bin/env python3
"""下載 Hahow 課程字幕並整理成逐字稿。"""
import argparse
import http.client
import json
import re
import sys
import urllib.request
from pathlib import Path

TIMESTAMP_PATTERN = re.compile(r'^\d{1,2}:\d{2}(:\d{2})?[.,]\d{3}\s+-->\s+')
INDEX_PATTERN = re.compile(r'^\d+$')
UNSAFE_FILENAME_PATTERN = re.compile(r'[/\\:*?"<>|]')


def srt_to_lines(srt):
    raw_lines = [raw_line.strip() for raw_line in srt.lstrip('﻿').splitlines()]
    lines = []
    for index, line in enumerate(raw_lines):
        next_line = raw_lines[index + 1] if index + 1 < len(raw_lines) else ''
        is_cue_index = INDEX_PATTERN.match(line) and TIMESTAMP_PATTERN.match(next_line)
        if not line or line == 'WEBVTT' or is_cue_index or TIMESTAMP_PATTERN.match(line):
            continue
        if lines and lines[-1] == line:
            continue
        lines.append(line)
    return lines


def safe_filename(name):
    return UNSAFE_FILENAME_PATTERN.sub('_', name).strip()


FAILED_MARK = '字幕下載失敗'
RAW_TITLE_MAX_LENGTH = 60


def fetch_text(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode('utf-8')


def build(manifest, out_root, fetch=fetch_text):
    out_dir = out_root / safe_filename(f"{manifest['course_id']}_{manifest['course_title']}")
    raw_dir = out_dir / 'raw'
    raw_dir.mkdir(parents=True, exist_ok=True)

    sections = [f"# {manifest['course_title']}\n"]
    failures = []
    for chapter in manifest['chapters']:
        sections.append(f"## {chapter['number']} - {chapter['title']}\n")
        for unit in chapter['units']:
            sections.append(f"### {unit['number']} {unit['title']}\n")
            try:
                srt = fetch(unit['srt_url'])
                lines = srt_to_lines(srt)
                if not lines:
                    raise ValueError('empty subtitle')
                raw_name = safe_filename(f"{unit['number']}_{unit['title'][:RAW_TITLE_MAX_LENGTH]}")
                (raw_dir / f'{raw_name}.srt').write_text(srt, encoding='utf-8')
            except (OSError, ValueError, http.client.HTTPException) as error:
                print(f"[失敗] {unit['number']} {unit['title']}: {error}", file=sys.stderr)
                failures.append(unit['number'])
                sections.append(f'{FAILED_MARK}\n')
                continue
            sections.append('\n'.join(lines) + '\n')

    (out_dir / 'transcript.md').write_text('\n'.join(sections), encoding='utf-8')
    return out_dir, failures


def main():
    parser = argparse.ArgumentParser(description='下載 Hahow 課程字幕並整理成逐字稿')
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--out', type=Path, default=Path.home() / 'Downloads' / 'hahow-subtitles')
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
    unit_count = sum(len(chapter['units']) for chapter in manifest['chapters'])
    out_dir, failures = build(manifest, args.out)

    print(f'輸出目錄：{out_dir}')
    print(f'成功 {unit_count - len(failures)} / {unit_count} 個單元')
    if failures:
        print(f"失敗單元：{', '.join(failures)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
