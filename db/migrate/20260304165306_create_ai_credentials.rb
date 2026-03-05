class CreateAiCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_credentials do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :api_key_ciphertext
      t.timestamps
    end

    add_index :ai_credentials, [ :profile_id, :provider ], unique: true
    add_column :profiles, :ai_provider, :string, default: "anthropic"
  end
end
