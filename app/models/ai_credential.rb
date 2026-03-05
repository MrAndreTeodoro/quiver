class AiCredential < ApplicationRecord
  belongs_to :profile

  # Encrypt API key at rest
  encrypts :api_key

  # Normalize blank strings to nil before validation
  before_validation :normalize_api_key

  # Callbacks - don't save blank API keys (keep existing value)
  # IMPORTANT: This MUST run before sync_api_key_ciphertext!
  before_save :preserve_existing_api_key_if_blank

  # Sync ciphertext with virtual attribute (workaround for Rails 8.1 encryption bug)
  before_save :sync_api_key_ciphertext, if: :api_key_changed?

  # Validations
  validates :provider, presence: true, inclusion: { in: %w[anthropic mistral openai kimi glm] }
  validates :provider, uniqueness: { scope: :profile_id }
  # Only validate api_key presence if user is actively trying to set/update it
  validates :api_key, presence: true, if: :should_validate_api_key?

  # Provider-specific model mappings (hardcoded)
  # Note: Only models marked with vision_supported: true can process images
  MODELS = {
    anthropic: {
      parser: "claude-sonnet-4-5-20250929",  # Use full model ID, not alias
      scorer: "claude-sonnet-4-5-20250929",
      generator: "claude-sonnet-4-5-20250929",
      vision_supported: true
    },
    mistral: {
      parser: "mistral-large-latest",
      scorer: "mistral-large-latest",
      generator: "mistral-large-latest",
      vision_supported: false
    },
    openai: {
      parser: "gpt-4o-mini",
      scorer: "gpt-4o",
      generator: "gpt-4o",
      vision_supported: true
    },
    kimi: {
      parser: "kimi-k2.5",
      scorer: "kimi-k2.5",
      generator: "kimi-k2.5",
      vision_supported: true
    },
    glm: {
      parser: "glm-4",
      scorer: "glm-4",
      generator: "glm-4",
      vision_supported: false
    }
  }.freeze

  def models
    MODELS[provider.to_sym]
  end

  def masked_api_key
    return nil if api_key.blank?
    return api_key if api_key.length <= 8

    "#{api_key[0..5]}...#{api_key[-4..]}"
  end

  # Override api_key getter to handle manual decryption (workaround for Rails 8.1)
  def api_key
    # Try to get the value from super (the virtual attribute)
    value = super

    # If super returns nil but we have ciphertext, decrypt manually
    if value.nil? && api_key_ciphertext.present?
      attr_type = self.class.type_for_attribute(:api_key)
      value = attr_type.deserialize(api_key_ciphertext)
    end

    value
  end

  private

  def normalize_api_key
    self.api_key = nil if api_key.present? && api_key.strip.empty?
  end

  def should_validate_api_key?
    # Only validate if api_key is being changed to something, or if it was set and is being removed
    # Don't validate if both old and new are blank (user never set this provider)
    return false if api_key.blank? && api_key_was.blank?
    return false if api_key.present? && api_key == api_key_was # No change
    true
  end

  def preserve_existing_api_key_if_blank
    Rails.logger.info "[AiCredential] preserve_existing_api_key_if_blank called"
    Rails.logger.info "[AiCredential] api_key: #{api_key.inspect}"
    Rails.logger.info "[AiCredential] api_key_was: #{api_key_was.inspect}"
    Rails.logger.info "[AiCredential] api_key_ciphertext: #{api_key_ciphertext.present? ? 'present' : 'blank'}"

    if api_key.nil? && api_key_was.present?
      Rails.logger.info "[AiCredential] Restoring api_key from api_key_was"
      self.api_key = api_key_was
    elsif api_key.blank? && api_key_ciphertext.present?
      # If api_key is blank string or nil but we have ciphertext, try to decrypt
      Rails.logger.info "[AiCredential] Attempting to restore from ciphertext"
      attr_type = self.class.type_for_attribute(:api_key)
      decrypted = attr_type.deserialize(api_key_ciphertext)
      if decrypted.present?
        Rails.logger.info "[AiCredential] Restored from ciphertext"
        self.api_key = decrypted
      end
    end
  end

  def sync_api_key_ciphertext
    return if api_key.nil?

    attr_type = self.class.type_for_attribute(:api_key)
    self.api_key_ciphertext = attr_type.serialize(api_key)
  end
end
