# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_04_165306) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_credentials", force: :cascade do |t|
    t.text "api_key_ciphertext"
    t.datetime "created_at", null: false
    t.integer "profile_id", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id", "provider"], name: "index_ai_credentials_on_profile_id_and_provider", unique: true
    t.index ["profile_id"], name: "index_ai_credentials_on_profile_id"
  end

  create_table "applications", force: :cascade do |t|
    t.string "application_status"
    t.datetime "applied_at"
    t.string "cover_letter_docx_path"
    t.text "cover_letter_markdown"
    t.string "cover_letter_md_path"
    t.string "cover_letter_pdf_path"
    t.datetime "created_at", null: false
    t.string "cv_docx_path"
    t.text "cv_markdown"
    t.string "cv_md_path"
    t.string "cv_pdf_path"
    t.datetime "generated_at"
    t.integer "job_offer_id", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["job_offer_id"], name: "index_applications_on_job_offer_id"
  end

  create_table "job_offers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "fit_gaps"
    t.text "fit_reasoning"
    t.float "fit_score"
    t.text "fit_strengths"
    t.string "parsed_company"
    t.string "parsed_location"
    t.text "parsed_requirements"
    t.text "parsed_skills"
    t.text "parsed_summary"
    t.string "parsed_title"
    t.text "raw_content"
    t.string "source_type"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "ai_provider", default: "anthropic"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_credentials", "profiles"
  add_foreign_key "applications", "job_offers"
end
