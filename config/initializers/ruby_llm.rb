# Dynamic AI provider configuration based on Profile settings
# This initializer runs on every request in development and on boot in production
# For a dynamic multi-provider setup, we'll configure at runtime in the services

module RubyLLM
  class Configuration
    class << self
      # Override the default configure to support dynamic provider switching
      def configure_for(profile)
        return unless profile&.active_credential

        credential = profile.active_credential
        provider = credential.provider.to_sym
        api_key = credential.api_key

        case provider
        when :anthropic
          RubyLLM.configure do |config|
            config.anthropic_api_key = api_key
          end
        when :openai
          RubyLLM.configure do |config|
            config.openai_api_key = api_key
          end
        when :mistral
          # Mistral uses OpenAI-compatible API
          RubyLLM.configure do |config|
            config.openai_api_key = api_key
            config.openai_api_base = "https://api.mistral.ai/v1"
          end
        when :kimi
          # Kimi (Moonshot AI) uses OpenAI-compatible API
          RubyLLM.configure do |config|
            config.openai_api_key = api_key
            config.openai_api_base = "https://api.moonshot.cn/v1"
          end
        when :glm
          # GLM (Zhipu AI) - would need custom adapter or OpenAI-compatible endpoint
          # For now, configure as OpenAI-compatible if available
          RubyLLM.configure do |config|
            config.openai_api_key = api_key
            config.openai_api_base = "https://open.bigmodel.cn/api/paas/v4"
          end
        end

        provider
      end
    end
  end
end

# Default configuration (fallback to ENV if no profile set yet)
RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "")
end
