---
name: jp-reference
description: Create a Japanese language reference HTML file with tables for grammar, conjugation, or vocabulary
argument-hint: <topic> [output-path]
---

Create a Japanese language reference page as an HTML fragment (no DOCTYPE, html, head, style, or body tags — just content HTML).

## Output location

Write the file to `frontend/public/fs-tree/r3vdy-2-b10vv/japanese/` unless the user specifies a different path via `$ARGUMENTS`.

## Format rules

- **No page boilerplate**: no `<!DOCTYPE>`, `<html>`, `<head>`, `<style>`, `<body>` tags. The file is included as a fragment inside an Astro layout.
- **Use `<h1>` for the page title**, `<h2>` for sections, `<h3>` for subsections.
- **Use `<table class="bordered">` for all structured data** — conjugations, word lists, comparisons, etc. The `bordered` class is defined in `frontend/src/assets/main.css` and adds borders and padding to tables.
- **Always provide furigana in parentheses** for kanji: 食べる（たべる）, 飲む（のむ）.
- **Include examples with translations** where helpful.
- **For grammar forms**: show how they attach to different word types (verbs, い-adj, な-adj, nouns) and note any irregularities.
- **For conjugation tables**: include columns for each verb/adjective group and show the formation rule, not just an example.
- **Keep explanations concise** — one sentence per meaning/nuance where possible.

## Existing pages for reference

These are in `frontend/public/fs-tree/r3vdy-2-b10vv/japanese/`:

Read one or two of these before writing to match the style and level of detail.
