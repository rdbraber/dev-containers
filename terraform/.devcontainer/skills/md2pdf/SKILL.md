---
name: md2pdf
description: Convert a Markdown file to PDF. Use when the user asks for a PDF of a .md file, or to export or print Markdown as PDF.
---

# Markdown to PDF

Convert Markdown to PDF with the `md2pdf` command (pandoc with Typst):

```sh
md2pdf <file.md> [output.pdf] [extra pandoc args...]
```

- Without an output path, the PDF is written next to the input file with a `.pdf` extension.
- Pass extra pandoc options only when the user asks for them, for example:
  - table of contents: `--toc`
  - font size: `-V fontsize=11pt`
  - title: `-M title="..."`
- `md2pdf` prints the PDF path on success. Report that path to the user.

If the conversion fails with a Typst error, explain the error and the offending text to the user.
Do not rewrite their Markdown to work around it unless they ask.
