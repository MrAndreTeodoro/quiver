# Quiver 🏹

A local Rails application that takes the grunt work out of job applications. Paste a job offer URL or upload a screenshot, and Quiver scores the fit against your professional profile, then generates a tailored CV and cover letter — ready to send.

---

## How It Works

1. **Ingest** — paste a job offer URL or upload a screenshot
2. **Parse** — Quiver extracts the role title, company, required skills, and key requirements
3. **Score** — your profile is compared against the job requirements and scored 0–100
4. **Generate** — if the fit score clears the threshold (default: 65), generate a tailored CV and cover letter
5. **Export** — download your documents in Markdown, DOCX, or PDF
6. **Track** — update the application status as you move through the hiring process

---

## Features

- **URL and image ingestion** — works with job board URLs or screenshots of job postings
- **AI-powered fit scoring** — weighted scoring across skills, experience level, domain relevance, and location compatibility
- **Honest document generation** — AI is explicitly instructed to use only real information from your profile, never invented metrics or experience
- **Three export formats** — Markdown, DOCX, and PDF for every document
- **Application tracker** — track status from applied → interviewing → offer/rejected across all your applications
- **Single profile** — maintain one master professional profile that all scoring and generation is based on

---

## Tech Stack

- **Ruby on Rails 8** — framework
- **SQLite3** — local database
- **TailwindCSS** — styling
- **ruby_llm** — AI model integration
- **Nokogiri + Faraday** — HTML parsing and HTTP
- **Caracal** — DOCX generation
- **Prawn** — PDF generation
- **ActiveStorage** — screenshot uploads

---

## Requirements

- Ruby 4.0+
- Node.js 20+
- An Anthropic API key

---

## Setup

### 1. Clone and install

```bash
git clone https://github.com/yourusername/quiver.git
cd quiver
bundle install
```

### 2. Set your API key

Create a `.env` file in the project root:

```
ANTHROPIC_API_KEY=your_key_here
```

### 3. Set up the database

```bash
rails db:setup
```

This runs migrations and seeds the default profile record.

### 4. Start the server

```bash
rails server
```

Open [http://localhost:3000](http://localhost:3000)

---

## First Run

Before adding any job offers, go to **Profile** and fill in your professional background. This is the document Quiver reads for every scoring and generation task — the more detail you provide, the better the output.

Recommended structure:
- Professional summary
- Technical skills by category
- Work experience with concrete achievements and metrics
- Education
- Work style and role preferences
- Personal projects

---

## Usage

### Adding a job offer

Click **Add Job Offer** and either:
- Paste the URL of the job posting, or
- Upload a screenshot of the job posting page

Quiver will automatically parse the content and score the fit.

### Generating documents

If the fit score is 65 or above, a **Generate Documents** button appears on the job offer page. Click it to generate a tailored CV and cover letter. Generation takes 15–30 seconds.

### Downloading

Once generated, the application page shows download links for all six files:
- CV — Markdown, DOCX, PDF
- Cover Letter — Markdown, DOCX, PDF

### Tracking applications

Update the application status directly from the application page:

| Status | Meaning |
|---|---|
| Not Applied | Documents generated, not yet sent |
| Applied | Application submitted |
| Interviewing | In the interview process |
| Offer | Received an offer |
| Rejected | Rejected by the company |
| Withdrawn | You withdrew the application |

---

## Configuration

### Fit threshold

The minimum score required to enable document generation. Default is **65**.

To change it, update the constant in `app/models/job_offer.rb`:

```ruby
FIT_THRESHOLD = 65.0
```

### AI models

Configured in `app/services/`. By default:
- Fast/cheap model for parsing (`claude-haiku-4-5-20251001`)
- Higher quality model for scoring and generation (`claude-sonnet-4-20250514`)

---

## Project Structure

```
app/
  models/
    profile.rb          # Single-record master profile
    job_offer.rb        # Job offer with parsed data and fit score
    application.rb      # Generated documents and application tracking
  services/
    job_parser_service.rb         # Fetch and parse job offers
    fit_scorer_service.rb         # Score fit against profile
    document_generator_service.rb # Generate CV and cover letter
    export_service.rb             # Coordinate file exports
    markdown_to_docx_service.rb   # Markdown → DOCX
    markdown_to_pdf_service.rb    # Markdown → PDF
storage/
  exports/              # All generated documents saved here
docs/
  prd/                  # Product requirements documents
```

---

## Privacy

Quiver runs entirely on your local machine. Your profile and job offer data stay in your local SQLite database. The only external calls made are to the AI API for parsing, scoring, and generation.

---

## License

MIT
