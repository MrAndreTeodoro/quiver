# Quiver — DOCX and PDF Export

---

## Overview

Two service classes handle conversion from Markdown to formatted files. Both are called by ExportService after Markdown content is generated.

Output directory: `Rails.root.join("storage", "exports")` — create with `FileUtils.mkdir_p` if missing.

---

## MarkdownToDocxService

File: `app/services/markdown_to_docx_service.rb`

Uses the Caracal gem to build DOCX files from parsed Markdown.

### Gem
`gem "caracal"`

### Markdown Parsing Strategy

Parse line by line:
- Lines starting with `# ` → H1
- Lines starting with `## ` → H2
- Lines starting with `### ` → H3
- Lines starting with `- ` or `* ` → bullet list item
- Blank lines → paragraph break
- All other lines → body paragraph

### Document Styling
- Page: A4, 15mm margins
- Body font: Arial 11pt
- H1: 16pt bold, space before 12pt
- H2: 13pt bold, space before 8pt
- H3: 11pt bold
- Bullets: indented 10mm, 10pt
- Line spacing: 1.15

### Implementation

```ruby
class MarkdownToDocxService
  def initialize(markdown, output_path)
    @markdown    = markdown
    @output_path = output_path
  end

  def call
    Caracal::Document.save(@output_path) do |doc|
      doc.page_size  { width 21_590; height 27_940 }
      doc.page_margins { top 1500; bottom 1500; left 1500; right 1500 }
      parse_lines(doc)
    end
  end

  private

  def parse_lines(doc)
    @markdown.each_line do |line|
      line = line.chomp
      if    line.start_with?("# ")  then doc.h1 line.sub("# ", "")
      elsif line.start_with?("## ") then doc.h2 line.sub("## ", "")
      elsif line.start_with?("### ") then doc.h3 line.sub("### ", "")
      elsif line.match?(/^[-*] /)   then doc.ul { doc.li line.sub(/^[-*] /, "") }
      elsif line.strip.empty?       then doc.p ""
      else                               doc.p line
      end
    end
  end
end
```

---

## MarkdownToPdfService

File: `app/services/markdown_to_pdf_service.rb`

Uses Prawn gem to build PDF files from parsed Markdown.

### Gems
```ruby
gem "prawn"
gem "prawn-table"
```

### Document Styling
- Page size: A4, margins: 42pt all sides
- Font: Helvetica (built-in)
- H1: 16pt bold, move_down 10 before, move_down 6 after
- H2: 13pt bold, move_down 8 before, move_down 4 after
- H3: 11pt bold, move_down 4 before
- Body: 10pt
- Bullets: 10pt, prefixed with "  • "
- Blank lines: move_down 6

### Implementation

```ruby
class MarkdownToPdfService
  def initialize(markdown, output_path)
    @markdown    = markdown
    @output_path = output_path
  end

  def call
    Prawn::Document.generate(@output_path, page_size: "A4", margin: [42, 42, 42, 42]) do |pdf|
      pdf.font "Helvetica"
      parse_lines(pdf)
    end
  end

  private

  def parse_lines(pdf)
    @markdown.each_line do |line|
      line = line.chomp
      if    line.start_with?("# ")
        pdf.move_down 10
        pdf.text line.sub("# ", ""), size: 16, style: :bold
        pdf.move_down 6
      elsif line.start_with?("## ")
        pdf.move_down 8
        pdf.text line.sub("## ", ""), size: 13, style: :bold
        pdf.move_down 4
      elsif line.start_with?("### ")
        pdf.move_down 4
        pdf.text line.sub("### ", ""), size: 11, style: :bold
      elsif line.match?(/^[-*] /)
        pdf.text "  \u2022 #{line.sub(/^[-*] /, "")}", size: 10
      elsif line.strip.empty?
        pdf.move_down 6
      else
        pdf.text line, size: 10
      end
    end
  end
end
```

---

## Notes for Future Iterations

- Inline bold/italic (`**text**`, `*text*`) ignored in v1. Add in v2 using Prawn's `inline_format: true` with regex substitution converting Markdown to Prawn tags
- If a file path is nil when download is attempted, controller should return a 404 with a flash error message
- Cover letter PDF should have slightly larger margins (50pt) than CV for better readability
