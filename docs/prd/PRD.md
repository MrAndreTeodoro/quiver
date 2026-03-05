# Quiver — Product Requirements Document

## Overview

Quiver is a local Rails application that automates the process of evaluating job offers and generating tailored CVs and cover letters. It ingests a job offer (via URL or screenshot), scores the fit against the user's professional profile, and — if the fit is above a configurable threshold — generates a tailored CV and cover letter in three formats: Markdown, DOCX, and PDF.

The application runs entirely on the local machine and is never deployed publicly.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Ruby on Rails 8.1.2 |
| Database | SQLite3 |
| CSS | TailwindCSS |
| JavaScript | Importmap |
| AI | ruby_llm gem |
| HTML parsing | Nokogiri |
| HTTP client | Faraday |
| DOCX export | Caracal gem |
| PDF export | Prawn + prawn-table gems |
| Image handling | ActiveStorage + mini_magick |

---

## Document Index

| File | Purpose |
|---|---|
| `AGENTS.md` | Entry point — project overview and setup for AI agents |
| `PRD.md` | This file — product overview and document index |
| `PRD_MODELS.md` | Database schema and model definitions |
| `PRD_SERVICES.md` | Business logic and service layer |
| `PRD_CONTROLLERS.md` | Controllers and routes |
| `PRD_VIEWS.md` | UI structure and views |
| `PRD_PROFILE.md` | The master profile document format |
| `PRD_EXPORTS.md` | DOCX and PDF export implementation |

---

## Core User Flow

1. User opens the app at `localhost:3000`
2. User pastes a job offer URL **or** uploads a screenshot of the job offer
3. App fetches and parses the job offer content using Nokogiri (URL) or Claude Vision (image)
4. App extracts structured data: title, company, location, skills, requirements
5. App scores the fit (0–100) by comparing the job requirements to the user's master profile
6. If score ≥ threshold (default: 65), user can trigger document generation
7. App generates a tailored CV and cover letter in Markdown, DOCX, and PDF
8. User downloads the documents and applies

---

## Key Constraints

- Local only — no authentication, no multi-user support
- Single profile — one Profile record in the database, editable via UI
- The fit threshold is configurable via a constant in the JobOffer model
- Never invent experience or metrics — AI prompts must be explicit about this
- All exports saved to `storage/exports/` inside the Rails app directory
- Applications track applied_at date and current status/result

---

## Fit Scoring Logic

Score from 0–100, weighted as follows:
- Technical skills match: 40%
- Experience level match: 30%
- Domain/industry relevance: 20%
- Location / remote compatibility: 10%

The score, reasoning, strengths, and gaps are all stored on the JobOffer record.

---

## Document Generation Rules

- Use Claude claude-sonnet-4-20250514 for all generation tasks
- CV must be tailored to the specific role but use only real information from the profile
- Cover letter must sound personal and warm, not templated
- Both documents generated in Markdown first, then converted to DOCX and PDF
- File naming convention: `{company}_{title}_{type}_{date}.{ext}` (slugified, lowercase)
