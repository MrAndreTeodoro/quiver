# Quiver — Models & Database Schema

## Models Overview

| Model | Purpose |
|---|---|
| `Profile` | Single-record master profile document |
| `JobOffer` | A job offer ingested from URL or image |
| `Application` | Generated documents + application lifecycle tracking |

---

## Profile

Single record only. Stores the user's full professional history in Markdown. This is what the AI reads when scoring and generating documents.

### Migration

```bash
rails generate model Profile name:string content:text
```

### Model

```ruby
class Profile < ApplicationRecord
  validates :content, presence: true

  def self.instance
    first_or_create!(name: "Default User", content: "")
  end
end
```

---

## JobOffer

Stores raw content, structured parsed data, AI scoring, and workflow status.

### Migration

```bash
rails generate model JobOffer \
  url:string \
  source_type:string \
  status:string \
  raw_content:text \
  parsed_title:string \
  parsed_company:string \
  parsed_location:string \
  parsed_skills:text \
  parsed_requirements:text \
  parsed_summary:text \
  fit_score:float \
  fit_reasoning:text \
  fit_strengths:text \
  fit_gaps:text
```

### Model

```ruby
class JobOffer < ApplicationRecord
  has_one :application, dependent: :destroy
  has_one_attached :screenshot

  FIT_THRESHOLD = 65.0

  enum :status, {
    pending:   "pending",
    parsed:    "parsed",
    scored:    "scored",
    generated: "generated",
    skipped:   "skipped"
  }

  enum :source_type, {
    url:   "url",
    image: "image"
  }

  def above_threshold?
    fit_score.present? && fit_score >= FIT_THRESHOLD
  end

  def parsed_skills_array
    JSON.parse(parsed_skills || "[]")
  rescue JSON::ParserError
    []
  end

  def fit_strengths_array
    JSON.parse(fit_strengths || "[]")
  rescue JSON::ParserError
    []
  end

  def fit_gaps_array
    JSON.parse(fit_gaps || "[]")
  rescue JSON::ParserError
    []
  end
end
```

---

## Application

Created when documents are generated. Stores Markdown content, export file paths, and tracks the application status and lifecycle.

### Migration

```bash
rails generate model Application \
  job_offer:references \
  cv_markdown:text \
  cover_letter_markdown:text \
  cv_docx_path:string \
  cv_pdf_path:string \
  cv_md_path:string \
  cover_letter_docx_path:string \
  cover_letter_pdf_path:string \
  cover_letter_md_path:string \
  generated_at:datetime \
  applied_at:datetime \
  application_status:string \
  notes:text
```

### Model

```ruby
class Application < ApplicationRecord
  belongs_to :job_offer

  enum :application_status, {
    not_applied:  "not_applied",
    applied:      "applied",
    interviewing: "interviewing",
    offer:        "offer",
    rejected:     "rejected",
    withdrawn:    "withdrawn"
  }

  def mark_applied!
    update!(application_status: "applied", applied_at: Time.current)
  end
end
```

---

## Setup Order

```bash
rails active_storage:install
rails generate model Profile name:string content:text
rails generate model JobOffer url:string source_type:string status:string raw_content:text parsed_title:string parsed_company:string parsed_location:string parsed_skills:text parsed_requirements:text parsed_summary:text fit_score:float fit_reasoning:text fit_strengths:text fit_gaps:text
rails generate model Application job_offer:references cv_markdown:text cover_letter_markdown:text cv_docx_path:string cv_pdf_path:string cv_md_path:string cover_letter_docx_path:string cover_letter_pdf_path:string cover_letter_md_path:string generated_at:datetime applied_at:datetime application_status:string notes:text
rails db:migrate
```
