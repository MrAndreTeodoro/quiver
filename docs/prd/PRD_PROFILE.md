# Quiver — Master Profile Document

The Profile record is the AI's source of truth for all scoring and generation. Keep it detailed.

---

## Format

Plain Markdown with clear headings. The AI reads this entire document for every scoring and generation task.

---

## Recommended Structure

Use these sections in this order:

1. **Header** — name, contact info, location
2. **Professional Summary** — 3-4 sentences: total experience, main specialisations, career direction
3. **Technical Skills** — grouped by category (Languages, Databases, Infrastructure, etc.)
4. **Professional Experience** — each role with company, dates, and bullet points with concrete achievements
5. **Education** — degrees, institutions, dates, context notes
6. **Work Style** — remote preference, collaboration style, role preferences
7. **Languages** — spoken languages and levels
8. **Personal Projects** — active side projects with brief descriptions

---

## Key Content Principles

- Include ALL technologies used per role, not just the headline ones
- Use the same bullet points from the CV for experience — they are already in good CAR format
- Add rough metrics wherever possible (200+ projects, 40 simultaneous environments, 60% load time reduction, etc.)
- Note career direction explicitly: "Targeting senior Rails/Python backend roles at product companies"
- List personal projects (Vinarist, MR TEO, Fairix, Negocios24, Mantsy) with tech stack

---

## Seeding the Profile on First Run

Add a seed in `db/seeds.rb` that pre-populates Profile with André's full professional background so the app is ready to use immediately after setup:

```ruby
Profile.find_or_create_by(name: "Default User") do |p|
  p.content = File.read(Rails.root.join("db", "profile_seed.md"))
end
```

Create `db/profile_seed.md` with the full profile content. This way `rails db:seed` loads the profile automatically.
