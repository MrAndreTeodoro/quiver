# Quiver — Views & UI

TailwindCSS for all styling. Clean, functional layout. No external UI component libraries needed.

---

## Layout — app/views/layouts/application.html.erb

- Left sidebar (fixed, 220px wide): App name "Quiver", nav links: Job Offers, Profile
- Main content area: remaining width with padding
- Flash messages at top of content area (green for notice, red for error)

---

## Job Offers

### index

Header with "Job Offers" title + "Add Job Offer" button linking to new.

Table with columns: Company | Role | Fit Score (colored badge) | Status | Application Status | Applied At | Actions (View, Delete)

Score badge colors: red bg if < 50, yellow if 50-64, green if >= 65.

Empty state if no job offers yet.

### new

Two-tab form controlled by a Stimulus tabs_controller:
- Tab 1 "Paste URL": text input for URL
- Tab 2 "Upload Screenshot": file input accepting image/*
- Hidden field source_type updated by Stimulus when switching tabs

Submit button: "Analyse Job Offer"

### show

Two-column layout (60/40 split):

Left column:
- Job title, company, location as heading
- Status badge, source_type badge
- Parsed summary
- Requirements text
- Skills as tags/chips
- Small "Re-parse" and "Re-score" buttons

Right column:
- Fit Score card: large colored number, reasoning text
- Strengths list with green checkmarks
- Gaps list with red X marks
- If above threshold and no application: "Generate Documents" button (POST to :generate)
- If below threshold: muted "Below threshold — generation disabled" message
- If application exists: link to application show

---

## Applications

### show

Top section: Job title, company, generated_at, link back to job offer.

Application Status card:
- Status select dropdown (all enum values as options)
- Applied at date input (show when status is applied or beyond)
- Notes textarea
- Save button (PATCH to update)

Documents section — two columns (CV | Cover Letter):
Each column has:
- Section heading
- Markdown rendered as HTML preview (in a scrollable container)
- Download buttons: MD, DOCX, PDF

---

## Profile

### show
Rendered Markdown preview. "Edit Profile" button top right.
Info note: "This profile is the source of truth for all AI scoring and generation. Keep it detailed."

### edit
Full-width textarea (min-height 600px, monospace font).
Placeholder guides the user to structure it with headings: Professional Summary, Technical Skills, Professional Experience, Education.
Save and Cancel buttons.

---

## Stimulus Controller — tabs_controller.js

File: app/javascript/controllers/tabs_controller.js

Controls the tab switching on the new job offer form.
Targets: urlTab, imageTab, urlPanel, imagePanel, sourceTypeField
showUrl() action: shows urlPanel, hides imagePanel, sets sourceTypeField value to "url"
showImage() action: shows imagePanel, hides urlPanel, sets sourceTypeField value to "image"

---

## Helper — render_markdown

Add to app/helpers/application_helper.rb using the redcarpet gem:

```ruby
def render_markdown(text)
  renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
  markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
  markdown.render(text.to_s).html_safe
end
```

Add to Gemfile: gem "redcarpet"
