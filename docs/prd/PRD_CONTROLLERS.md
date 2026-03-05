# Quiver — Controllers & Routes

---

## Routes

```ruby
Rails.application.routes.draw do
  root "job_offers#index"

  resources :job_offers do
    member do
      post :parse
      post :score
      post :generate
    end
  end

  resource :profile, only: [:show, :edit, :update]

  resources :applications, only: [:show, :update] do
    member do
      get :download_cv_md
      get :download_cv_docx
      get :download_cv_pdf
      get :download_cover_letter_md
      get :download_cover_letter_docx
      get :download_cover_letter_pdf
    end
  end
end
```

---

## JobOffersController

File: `app/controllers/job_offers_controller.rb`

### index
List all job offers ordered by created_at desc. Include associated application if present.

### new
Render form with two modes toggled by a tab UI: URL input OR image file upload. Use a hidden `source_type` field that updates based on which tab is active.

### create
Create JobOffer record. If source_type is "url" save the url. If "image" attach the uploaded file via ActiveStorage. After save, automatically call `JobParserService` then `FitScorerService` inline (local app — no background jobs needed). Redirect to show.

### show
Display parsed info, fit score breakdown (score, reasoning, strengths, gaps). If above threshold show "Generate Documents" button. If application exists, show download links and application status.

### destroy
Delete job offer and associated application.

### parse (POST member)
Re-run `JobParserService` on the job offer. Redirect to show.

### score (POST member)
Re-run `FitScorerService` on the job offer. Redirect to show.

### generate (POST member)
Run `DocumentGeneratorService`. Guard: only allow if `above_threshold?` is true. Redirect to show.

---

## ApplicationsController

File: `app/controllers/applications_controller.rb`

### show
Display CV and cover letter Markdown previews (rendered as HTML), all download links, application status form, applied_at, notes.

### update
Update `application_status`, `applied_at` (auto-set to now if blank and status is "applied"), and `notes`. Redirect to show.

### Download actions (6 total)
`download_cv_md`, `download_cv_docx`, `download_cv_pdf`, `download_cover_letter_md`, `download_cover_letter_docx`, `download_cover_letter_pdf`

Each action calls `send_file` with the corresponding path stored on the application record, `disposition: :attachment`, and the correct `content_type`.

Content types:
- `.md` → `text/markdown`
- `.docx` → `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- `.pdf` → `application/pdf`

---

## ProfilesController

File: `app/controllers/profiles_controller.rb`

### show
Display `Profile.instance` content rendered as Markdown (use a gem like `redcarpet` or `commonmarker`).

### edit
Textarea form for `Profile.instance.content`. Include helper note: "This is your master professional profile. Be as detailed as possible — the AI uses this to score job offers and generate all documents."

### update
Update `Profile.instance`. Redirect to show.

---

## ApplicationController

```ruby
class ApplicationController < ActionController::Base
  rescue_from StandardError do |e|
    flash[:error] = "Something went wrong: #{e.message}"
    redirect_back fallback_location: root_path
  end
end
```
