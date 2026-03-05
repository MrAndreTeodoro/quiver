class CreateJobOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :job_offers do |t|
      t.string :url
      t.string :source_type
      t.string :status
      t.text :raw_content
      t.string :parsed_title
      t.string :parsed_company
      t.string :parsed_location
      t.text :parsed_skills
      t.text :parsed_requirements
      t.text :parsed_summary
      t.float :fit_score
      t.text :fit_reasoning
      t.text :fit_strengths
      t.text :fit_gaps

      t.timestamps
    end
  end
end
