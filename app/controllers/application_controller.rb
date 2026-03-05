class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from StandardError do |e|
    Rails.logger.error "Application error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:error] = "Something went wrong: #{e.message}"
    redirect_back fallback_location: root_path
  end
end
