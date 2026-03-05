class ProfilesController < ApplicationController
  before_action :set_profile

  def show
  end

  def edit
    # Ensure we have AI credential records for all providers
    %w[anthropic mistral openai kimi glm].each do |provider|
      @profile.ensure_ai_credential_for(provider)
    end
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      Rails.logger.error "Profile update failed: #{@profile.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.instance
  end

  def profile_params
    params.require(:profile).permit(
      :name,
      :content,
      :ai_provider,
      ai_credentials_attributes: [ :id, :provider, :api_key, :_destroy ]
    )
  end
end
