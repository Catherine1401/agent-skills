---
name: quizz
description: Convert a multiple-choice question bank with an answer key (PDF, DOCX, or similar) into Wayground (Quizizz) import spreadsheets built from the bundled Wayground template. Use when asked to create Wayground/Quizizz quizzes or import files from a question bank.
---

- Use only `Multiple Choice` (one correct answer) and `Checkbox` (several correct answers).
- Take correct answers only from the source's answer key; never decide answers yourself. If the source has more than one key (e.g. summary table and per-question explanations), cross-check them and report mismatches instead of picking one.
- Source layouts differ per file: inspect the source and write a one-off extractor for it in a temp directory (`pdftotext` for PDF, `python-docx` or `pandoc` for DOCX); do not reuse a previous source's extractor unchecked. Strip page headers/footers and section titles that leak into question or option text.
- Extract to JSON: `[{"num", "text", "options": [2-5 strings in source order], "correct": [0-based indices], "explanation": string|null}]`. Explanation = the source's explanation without the restated answer.
- `scripts/write.py <json> <out_dir> <prefix> [template.xlsx]` copies `assets/template.xlsx` (or the user's newer template when given) (keeps header, instruction row 2, dropdowns), puts correct options first in source order (Correct Answer `1` or `1,2,...,N`), wrong options after in source order, time 30s, 50 questions per file named `<prefix>_<first>-<last>.xlsx`.
- `scripts/check.py <json> <out_dir> <prefix>` must report every file `bad []` and `coverage complete: True`.
- `check.py` only proves the xlsx matches the JSON. Before reporting success, also verify the JSON against the source: question count equals the source's count, every question has its answer from the key, and no header/footer text remains.
- When the user supplies a template, confirm its columns A–K are: Question Text, Question Type, Option 1–5, Correct Answer, Time in seconds, Image Link, Answer explanation. Default output directory: current working directory.
