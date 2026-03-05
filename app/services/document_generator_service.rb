class DocumentGeneratorService
  def initialize(job_offer)
    @job_offer = job_offer
    @profile = Profile.instance
    @credential = @profile.active_credential
  end

  def call
    if @profile.content.blank?
      raise "Profile is empty. Please add your professional profile before generating documents."
    end

    raise "No AI provider configured. Please add an API key in your profile settings." unless @credential

    unless @job_offer.above_threshold?
      raise "Job offer fit score (#{@job_offer.fit_score}) is below the threshold (#{JobOffer::FIT_THRESHOLD})"
    end

    # Generate CV and Cover Letter
    cv_markdown = generate_cv(@profile.content)
    cover_letter_markdown = generate_cover_letter(@profile.content)

    # Find or create application record
    application = Application.find_or_initialize_by(job_offer: @job_offer)
    application.assign_attributes(
      cv_markdown: cv_markdown,
      cover_letter_markdown: cover_letter_markdown,
      generated_at: Time.current,
      application_status: application.new_record? ? "not_applied" : application.application_status
    )
    application.save!

    # Generate exports
    ExportService.new(application).call

    # Update job offer status
    @job_offer.update!(status: "generated")

    application
  rescue => e
    Rails.logger.error "DocumentGeneratorService failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def configure_ai_client
    provider = @credential.provider.to_sym
    api_key = @credential.api_key

    case provider
    when :anthropic
      RubyLLM.configure { |c| c.anthropic_api_key = api_key }
    when :openai
      RubyLLM.configure { |c| c.openai_api_key = api_key }
    when :mistral
      RubyLLM.configure { |c| c.openai_api_key = api_key; c.openai_api_base = "https://api.mistral.ai/v1" }
    when :kimi
      RubyLLM.configure { |c| c.openai_api_key = api_key; c.openai_api_base = "https://api.moonshot.cn/v1" }
    when :glm
      RubyLLM.configure { |c| c.openai_api_key = api_key; c.openai_api_base = "https://open.bigmodel.cn/api/paas/v4" }
    end
  end

  def generate_cv(profile_content)
    configure_ai_client

    job_info = {
      title: @job_offer.parsed_title,
      company: @job_offer.parsed_company,
      location: @job_offer.parsed_location,
      skills: @job_offer.parsed_skills_array,
      requirements: @job_offer.parsed_requirements,
      summary: @job_offer.parsed_summary
    }

    prompt = <<~PROMPT
      Generate a professional CV/resume tailored for this specific job offer.

      CRITICAL INSTRUCTIONS:
      - Use ONLY information from the candidate's profile — never invent experience, metrics, or skills
      - Emphasize and reorder content to match the specific job requirements
      - Target length: 600–800 words
      - Return clean Markdown only — no preamble, no commentary

      REQUIRED SECTIONS:
      1. Professional Summary (3-4 sentences referencing the specific role at #{job_info[:company]})
      2. Technical Skills (organized by category, prioritizing job-relevant skills)
      3. Professional Experience (with bullet points highlighting relevant achievements)
      4. Education

      CANDIDATE PROFILE:
      ---
      #{profile_content}
      ---

      JOB OFFER:
      ---
      #{job_info.to_json}
      ---
    PROMPT

    chat = RubyLLM.chat(model: @credential.models[:generator])
    response = chat.ask(prompt)

    response.content.to_s.strip
  end

  def generate_cover_letter(profile_content)
    configure_ai_client

    job_info = {
      title: @job_offer.parsed_title,
      company: @job_offer.parsed_company,
      location: @job_offer.parsed_location,
      skills: @job_offer.parsed_skills_array,
      requirements: @job_offer.parsed_requirements,
      summary: @job_offer.parsed_summary
    }

    prompt = <<~PROMPT
      Write a personalized cover letter for this job application.

      CRITICAL INSTRUCTIONS:
      - Sound personal and warm — not templated or generic
      - NEVER start with "I am writing to express my interest in..." or similar clichés
      - Reference something specific about the company or role that shows genuine interest
      - Use only real information from the candidate's profile
      - 3–4 paragraphs total
      - Confident, forward-looking closing
      - Return clean Markdown only — no preamble, no commentary

      CANDIDATE PROFILE:
      ---
      #{profile_content}
      ---

      JOB OFFER:
      ---
      #{job_info.to_json}
      ---
    PROMPT

    chat = RubyLLM.chat(model: @credential.models[:generator])
    response = chat.ask(prompt)

    response.content.to_s.strip
  end
end
