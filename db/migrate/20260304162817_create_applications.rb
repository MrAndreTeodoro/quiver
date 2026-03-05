class CreateApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :applications do |t|
      t.references :job_offer, null: false, foreign_key: true
      t.text :cv_markdown
      t.text :cover_letter_markdown
      t.string :cv_docx_path
      t.string :cv_pdf_path
      t.string :cv_md_path
      t.string :cover_letter_docx_path
      t.string :cover_letter_pdf_path
      t.string :cover_letter_md_path
      t.datetime :generated_at
      t.datetime :applied_at
      t.string :application_status
      t.text :notes

      t.timestamps
    end
  end
end
