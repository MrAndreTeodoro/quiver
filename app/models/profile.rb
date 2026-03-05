class Profile < ApplicationRecord
  has_many :ai_credentials, dependent: :destroy
  accepts_nested_attributes_for :ai_credentials,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["api_key"].blank? && attrs["id"].present? }

  validates :content, presence: true

  def self.instance
    first_or_create!(name: "André Teodoro", content: "")
  end

  def active_credential
    ai_credentials.find_by(provider: ai_provider)
  end

  def api_key_for(provider)
    credential = ai_credentials.find_by(provider: provider)
    credential&.api_key
  end

  def masked_api_key_for(provider)
    credential = ai_credentials.find_by(provider: provider)
    credential&.masked_api_key
  end

  def has_credential_for?(provider)
    credential = ai_credentials.find_by(provider: provider)
    credential&.api_key.present?
  end

  def ensure_ai_credential_for(provider)
    ai_credentials.find_or_initialize_by(provider: provider)
  end
end
