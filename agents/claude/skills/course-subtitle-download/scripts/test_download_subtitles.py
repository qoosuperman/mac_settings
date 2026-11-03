import http.client
import tempfile
import unittest
from pathlib import Path

from download_subtitles import RAW_TITLE_MAX_LENGTH, build, safe_filename, srt_to_lines


class SrtToLinesTest(unittest.TestCase):
    def test_strips_index_and_timestamps(self):
        srt = "1\n00:00:00,000 --> 00:00:01,106\n你好 我是 Ryan\n\n2\n00:00:01,106 --> 00:00:02,373\n在過去的幾年裡\n"
        self.assertEqual(srt_to_lines(srt), ["你好 我是 Ryan", "在過去的幾年裡"])

    def test_keeps_multiline_cue(self):
        srt = "1\n00:00:00,000 --> 00:00:01,000\n第一行\n第二行\n"
        self.assertEqual(srt_to_lines(srt), ["第一行", "第二行"])

    def test_handles_crlf_and_bom(self):
        srt = "﻿1\r\n00:00:00,000 --> 00:00:01,000\r\n內容\r\n\r\n"
        self.assertEqual(srt_to_lines(srt), ["內容"])

    def test_handles_webvtt(self):
        vtt = "WEBVTT\n\n00:00.000 --> 00:01.106\n你好\n"
        self.assertEqual(srt_to_lines(vtt), ["你好"])

    def test_keeps_digit_only_cue_text(self):
        srt = "1\n00:00:00,000 --> 00:00:01,000\n2022\n\n2\n00:00:01,000 --> 00:00:02,000\n下一句\n"
        self.assertEqual(srt_to_lines(srt), ["2022", "下一句"])

    def test_drops_consecutive_duplicates(self):
        srt = "1\n00:00:00,000 --> 00:00:01,000\n重複\n\n2\n00:00:01,000 --> 00:00:02,000\n重複\n"
        self.assertEqual(srt_to_lines(srt), ["重複"])


class SafeFilenameTest(unittest.TestCase):
    def test_safe_filename_replaces_path_chars(self):
        self.assertEqual(safe_filename(' 高效 AI 投資術：No Code / 理專 '), '高效 AI 投資術：No Code _ 理專')
        self.assertEqual(safe_filename('a:b*c?"<>|\\d'), 'a_b_c______d')


SRT_A = "1\n00:00:00,000 --> 00:00:01,000\n課程介紹內容\n"
SRT_B = "1\n00:00:00,000 --> 00:00:01,000\n風險評估內容\n"


def make_manifest(course_title='測試課程'):
    return {
        'course_id': 'abc123',
        'course_title': course_title,
        'chapters': [
            {
                'number': '1',
                'title': '基礎知識',
                'units': [
                    {'number': '1-1', 'title': '課程介紹', 'srt_url': 'https://example/a'},
                    {'number': '1-2', 'title': '風險評估', 'srt_url': 'https://example/b'},
                ],
            },
        ],
    }


class BuildTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out_root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_writes_transcript_and_raw_files(self):
        responses = {'https://example/a': SRT_A, 'https://example/b': SRT_B}

        out_dir, failures = build(make_manifest(), self.out_root, fetch=responses.__getitem__)

        self.assertEqual(out_dir, self.out_root / 'abc123_測試課程')
        self.assertEqual(failures, [])
        self.assertEqual((out_dir / 'raw' / '1-1_課程介紹.srt').read_text(encoding='utf-8'), SRT_A)
        self.assertEqual(
            (out_dir / 'transcript.md').read_text(encoding='utf-8'),
            '# 測試課程\n\n## 1 - 基礎知識\n\n### 1-1 課程介紹\n\n課程介紹內容\n\n'
            '### 1-2 風險評估\n\n風險評估內容\n',
        )

    def test_failed_unit_is_marked_and_others_continue(self):
        def fetch(url):
            if url == 'https://example/a':
                raise OSError('timeout')
            return SRT_B

        out_dir, failures = build(make_manifest(), self.out_root, fetch=fetch)

        self.assertEqual(failures, ['1-1'])
        transcript = (out_dir / 'transcript.md').read_text(encoding='utf-8')
        self.assertIn('### 1-1 課程介紹\n\n字幕下載失敗\n', transcript)
        self.assertIn('風險評估內容', transcript)
        self.assertFalse((out_dir / 'raw' / '1-1_課程介紹.srt').exists())

    def test_incomplete_read_counts_as_failure(self):
        def fetch(url):
            if url == 'https://example/a':
                raise http.client.IncompleteRead(b'partial')
            return SRT_B

        out_dir, failures = build(make_manifest(), self.out_root, fetch=fetch)

        self.assertEqual(failures, ['1-1'])
        self.assertIn('風險評估內容', (out_dir / 'transcript.md').read_text(encoding='utf-8'))

    def test_long_unit_title_is_truncated_in_raw_filename(self):
        manifest = make_manifest()
        manifest['chapters'][0]['units'][0]['title'] = '很長的單元名稱' * 20
        responses = {'https://example/a': SRT_A, 'https://example/b': SRT_B}

        out_dir, failures = build(manifest, self.out_root, fetch=responses.__getitem__)

        self.assertEqual(failures, [])
        raw_names = sorted(path.name for path in (out_dir / 'raw').iterdir())
        self.assertEqual(raw_names[0], f"1-1_{('很長的單元名稱' * 20)[:RAW_TITLE_MAX_LENGTH]}.srt")

    def test_empty_subtitle_counts_as_failure(self):
        responses = {'https://example/a': '  \n', 'https://example/b': SRT_B}

        _, failures = build(make_manifest(), self.out_root, fetch=responses.__getitem__)

        self.assertEqual(failures, ['1-1'])

    def test_course_title_with_slash(self):
        responses = {'https://example/a': SRT_A, 'https://example/b': SRT_B}

        out_dir, _ = build(make_manifest('A/B 課程'), self.out_root, fetch=responses.__getitem__)

        self.assertEqual(out_dir, self.out_root / 'abc123_A_B 課程')

    def test_rerun_overwrites_output(self):
        def failing_fetch(url):
            raise OSError('timeout')

        build(make_manifest(), self.out_root, fetch=failing_fetch)
        responses = {'https://example/a': SRT_A, 'https://example/b': SRT_B}
        out_dir, failures = build(make_manifest(), self.out_root, fetch=responses.__getitem__)

        self.assertEqual(failures, [])
        self.assertNotIn('字幕下載失敗', (out_dir / 'transcript.md').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
