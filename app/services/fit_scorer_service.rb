class FitScorerService
  def initialize(job_offer)
    @job_offer = job_offer
    @profile = Profile.instance
    @credential = @profile.active_credential
  end

  def call
    if @profile.content.blank?
      raise "Profile is empty. Please add your professional profile before scoring job offers."
    end

    raise "No AI provider configured. Please add an API key in your profile settings." unless @credential

    result = score_with_ai(@profile.content)

    @job_offer.update!(
      fit_score: result["score"],
      fit_reasoning: result["reasoning"],
      fit_strengths: result["strengths"].to_json,
      fit_gaps: result["gaps"].to_json,
      status: result["score"] >= JobOffer::FIT_THRESHOLD ? "scored" : "skipped"
    )

    @job_offer
  rescue => e
    Rails.logger.error "FitScorerService failed: #{e.message}"
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

  def score_with_ai(profile_content)
    configure_ai_client

    job_data = {
      title: @job_offer.parsed_title,
      company: @job_offer.parsed_company,
      location: @job_offer.parsed_location,
      skills: @job_offer.parsed_skills_array,
      requirements: @job_offer.parsed_requirements,
      summary: @job_offer.parsed_summary
    }

    prompt = <<~PROMPT
      Compare this job offer against the candidate's profile and score the fit from 0-100.

      SCORING CRITERIA (be honest and critical):
      - Technical skills match: 40% weight
      - Experience level match: 30% weight#{'  '}
      - Domain/industry relevance: 20% weight
      - Location / remote compatibility: 10% weight

      Return ONLY a valid JSON object with these exact keys:
      - "score": integer from 0-100
      - "reasoning": detailed explanation of the score (2-3 sentences)
      - "strengths": array of strings listing candidate strengths for this role
      - "gaps": array of strings listing areas where the candidate may be lacking

      Do not wrap the JSON in markdown code blocks. Return raw JSON only.
      Do not invent skills or experience the candidate doesn't have. Be objective and critical.

      CANDIDATE PROFILE:
      ---
      #{profile_content}
      ---

      JOB OFFER:
      ---
      #{job_data.to_json}
      ---
    PROMPT

    chat = RubyLLM.chat(model: @credential.models[:scorer])
    response = chat.ask(prompt)

    content = response.content.to_s.strip
    content = content.gsub(/^```json\s*/, "").gsub(/\s*```$/, "")

    result = JSON.parse(content)

    required_keys = [ "score", "reasoning", "strengths", "gaps" ]
    missing_keys = required_keys - result.keys

    if missing_keys.any?
      raise "AI response missing required keys: #{missing_keys.join(', ')}"
    end

    result["score"] = [ [ result["score"].to_i, 0 ].max, 100 ].min
    result["strengths"] = Array(result["strengths"])
    result["gaps"] = Array(result["gaps"])

    result
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response as JSON: #{e.message}"
    Rails.logger.error "Response content: #{response&.content}"

    {
      "score" => 50,
      "reasoning" => "Unable to parse detailed scoring results",
      "strengths" => [],
      "gaps" => [ "Unable to determine fit gaps" ]
    }
  end
end
