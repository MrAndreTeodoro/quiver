# Quiver — Service Layer

All business logic lives in service objects under `app/services/`. Each service does one thing.

---

## JobParserService

**Purpose:** Fetches and parses a job offer from URL or image, extracts structured data using AI.

**File:** `app/services/job_parser_service.rb`

### Responsibilities

- If `source_type` is `"url"`: fetch with Faraday, parse HTML with Nokogiri, strip nav/footer/scripts, extract main content
- If `source_type` is `"image"`: download screenshot from ActiveStorage, send to AI vision model to extract plain text
- Send raw text to AI to extract structured JSON: title, company, location, skills (array), requirements, summary
- Update JobOffer with parsed fields and set status to `"parsed"`

### URL Fetching Notes

- Set a realistic User-Agent header to avoid request blocks
- Target selectors: `main`, `article`, `[class*='job']`, `[id*='job']`, `[class*='description']`
- Fall back to full body text if no main content container found
- Strip: `nav`, `footer`, `header`, `script`, `style`, `noscript`, `aside`

### AI Parsing Prompt Requirements

Use a fast model. Return ONLY valid JSON, no markdown fences. Expected keys: `title`, `company`, `location`, `skills` (array), `requirements`, `summary`. Handle `JSON::ParserError` with a fallback hash.

### Image Extraction

Download screenshot bytes from ActiveStorage, base64-encode, send to AI vision endpoint with instruction to extract all text from the image preserving structure.

---

## FitScorerService

**Purpose:** Compares job requirements against the user's profile, returns a 0–100 fit score.

**File:** `app/services/fit_scorer_service.rb`

### Scoring Weights

| Criteria | Weight |
|---|---|
| Technical skills match | 40% |
| Experience level match | 30% |
| Domain/industry relevance | 20% |
| Location / remote compatibility | 10% |

### Responsibilities

- Read `Profile.instance.content`
- Build prompt with profile content + job parsed data
- Call AI model (higher quality), expect JSON: `score` (int 0-100), `reasoning` (string), `strengths` (array), `gaps` (array)
- Update JobOffer: `fit_score`, `fit_reasoning`, `fit_strengths` (JSON array), `fit_gaps` (JSON array)
- Set status to `"scored"` if score >= `FIT_THRESHOLD`, `"skipped"` if below

### AI Prompt Requirements

Instruct the model to be honest and critical. Include scoring weights explicitly. Return ONLY valid JSON, no markdown fences. Handle `JSON::ParserError` gracefully.

---

## DocumentGeneratorService

**Purpose:** Generates tailored CV and cover letter in Markdown, then triggers ExportService.

**File:** `app/services/document_generator_service.rb`

### Responsibilities

- Generate CV Markdown
- Generate cover letter Markdown
- Create `Application` record: both Markdown strings, `generated_at: Time.current`, `application_status: "not_applied"`
- Call `ExportService.new(application).call`
- Update JobOffer status to `"generated"`
- Return the application record

### CV Generation Prompt Requirements

- Use ONLY information from the candidate profile — never invent experience, metrics, or skills
- Emphasise and reorder content to match the specific job
- Sections: Professional Summary, Technical Skills, Professional Experience, Education
- Summary must reference the specific role and company
- Target length: 600–800 words
- Return clean Markdown only — no preamble, no commentary

### Cover Letter Prompt Requirements

- Sound personal and warm — not templated
- Never start with "I am writing to express my interest"
- Reference something specific about the company or role
- Use only real information from the profile
- 3–4 paragraphs, confident closing
- Return clean Markdown only — no preamble, no commentary

---

## ExportService

**Purpose:** Converts Markdown to DOCX and PDF, saves files to disk, updates Application with paths.

**File:** `app/services/export_service.rb`

### Output Directory

`Rails.root.join("storage", "exports")` — create with `FileUtils.mkdir_p` if missing.

### File Naming

`{company}_{title}_{date}_{type}.{ext}` — fully slugified with `.parameterize`, lowercase.
Example: `acme_rails-developer_20260301_cv.docx`

### Responsibilities

- Build slug from company + title + today's date
- For CV: write `.md`, call `MarkdownToDocxService`, call `MarkdownToPdfService`
- For cover letter: same three exports
- Update Application record with all 6 file paths (cv_md_path, cv_docx_path, cv_pdf_path, cover_letter_md_path, cover_letter_docx_path, cover_letter_pdf_path)

---

## MarkdownToDocxService

Converts a Markdown string to a `.docx` file using Caracal.
**File:** `app/services/markdown_to_docx_service.rb`
See `PRD_EXPORTS.md` for full implementation.

---

## MarkdownToPdfService

Converts a Markdown string to a `.pdf` file using Prawn.
**File:** `app/services/markdown_to_pdf_service.rb`
See `PRD_EXPORTS.md` for full implementation.
