class JobParserService
  def initialize(job_offer)
    @job_offer = job_offer
    @profile = Profile.instance
    @credential = @profile.active_credential
  end

  def call
    raise "No AI provider configured. Please add an API key in your profile settings." unless @credential

    if @job_offer.url.present?
      # Give URL directly to AI for parsing
      parsed_data = parse_url_with_ai
      raw_content = "URL: #{@job_offer.url}"
    elsif @job_offer.screenshot.attached?
      # Use image extraction for screenshots
      extracted_text = extract_text_from_image
      parsed_data = parse_with_ai(extracted_text)
      raw_content = extracted_text
    else
      raise "No URL or screenshot provided for job offer"
    end

    @job_offer.update!(
      raw_content: raw_content,
      parsed_title: parsed_data["title"],
      parsed_company: parsed_data["company"],
      parsed_location: parsed_data["location"],
      parsed_skills: parsed_data["skills"].to_json,
      parsed_requirements: parsed_data["requirements"],
      parsed_summary: parsed_data["summary"],
      status: "parsed"
    )

    @job_offer
  rescue => e
    Rails.logger.error "JobParserService failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  # Extracts the first valid JSON object from text, handling nested braces
  def extract_first_json_object(text)
    start_idx = text.index("{")
    return nil unless start_idx

    # Find the matching closing brace by tracking brace depth
    depth = 1
    pos = start_idx + 1

    while pos < text.length && depth > 0
      case text[pos]
      when "{"
        depth += 1
      when "}"
        depth -= 1
      when '"'
        # Skip to end of string, handling escaped quotes
        pos += 1
        while pos < text.length
          if text[pos] == "\\" && pos + 1 < text.length
            pos += 2  # Skip escaped character
          elsif text[pos] == '"'
            break
          else
            pos += 1
          end
        end
      end
      pos += 1
    end

    # If we found a complete object at depth 0
    if depth == 0
      json_str = text[start_idx...pos]
      begin
        return JSON.parse(json_str)
      rescue JSON::ParserError
        return nil
      end
    end

    nil
  end

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

  def parse_url_with_ai
    configure_ai_client

    url = @job_offer.url

    puts "\n" + "=" * 80
    puts "URL PARSING - Job Offer ID: #{@job_offer.id}"
    puts "URL: #{url}"
    puts "=" * 80

    # Fetch HTML content
    puts "Fetching HTML..."
    html = fetch_url_html(url)
    puts "HTML fetched: #{html.length} chars"

    # Clean HTML but keep structure
    puts "Cleaning HTML..."
    text = clean_html(html)
    puts "Cleaned text: #{text.length} chars"
    puts "=" * 80

    # Truncate if too long
    text_for_ai = text[0..8000]  # Limit to prevent token overflow

    # Simple, direct prompt with clearer instructions
    prompt = <<~PROMPT
      Extract job posting details from the text below and return ONLY a JSON object with these exact keys. Replace the placeholders with actual extracted values.

      JSON structure to return:
      - "title": The job title (e.g., "Senior Software Engineer")
      - "company": The company name (e.g., "Google")
      - "location": Job location (e.g., "San Francisco, CA" or "Remote")
      - "skills": Array of technical skills mentioned (e.g., ["Ruby", "Rails", "PostgreSQL"])
      - "requirements": Brief summary of key requirements (2-3 sentences)
      - "summary": Brief job description summary (2-3 sentences)

      Job posting text to analyze:
      ---
      #{text_for_ai}
      ---

      Return ONLY valid JSON. Example response format:
      {"title": "Senior Developer", "company": "Acme Corp", "location": "Remote", "skills": ["Python", "AWS"], "requirements": "5+ years experience required.", "summary": "Leading engineering team to build cloud solutions."}
    PROMPT

    puts "Sending to AI..."
    Rails.logger.info "Sending #{text_for_ai.length} chars to AI..."

    chat = RubyLLM.chat(model: @credential.models[:parser])
    response = chat.ask(prompt)

    raw_response = response.content.to_s

    puts "\nAI RESPONSE (first 500 chars):"
    puts raw_response[0..500]
    puts "\n"

    Rails.logger.info "AI RESPONSE: #{raw_response[0..500]}"

    # Extract JSON - handle both plain JSON and markdown-wrapped JSON
    content = raw_response.strip

    # Try to extract JSON from markdown code block if present
    if content =~ /```json\s*(.*?)\s*```/m
      content = $1.strip
    elsif content =~ /```\s*(.*?)\s*```/m
      content = $1.strip
    end

    puts "Parsing JSON..."
    puts "Content to parse (first 500 chars): #{content[0..500]}"

    begin
      result = JSON.parse(content)
    rescue JSON::ParserError => e
      # Try to extract the first valid JSON object
      result = extract_first_json_object(content)

      unless result
        Rails.logger.error "JSON extraction failed: #{e.message}"
        Rails.logger.error "Raw content: #{raw_response[0..1000]}"
        raise e
      end
    end

    # Ensure all required keys exist
    required_keys = %w[title company location skills requirements summary]
    required_keys.each do |key|
      result[key] = "Unknown" if result[key].nil? || result[key] == ""
    end
    result["skills"] = [] if result["skills"].nil? || !result["skills"].is_a?(Array)

    puts "✓ PARSED SUCCESSFULLY:"
    puts "  Title: #{result['title']}"
    puts "  Company: #{result['company']}"
    puts "  Location: #{result['location']}"
    puts "=" * 80

    Rails.logger.info "PARSED: title=#{result['title']}, company=#{result['company']}"

    result
  end

  def fetch_url_html(url)
    conn = Faraday.new do |f|
      f.response :follow_redirects, limit: 3
      f.adapter Faraday.default_adapter
    end

    response = conn.get(url) do |req|
      req.headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
      req.headers["Accept"] = "text/html"
    end

    if response.success?
      html = response.body.dup.force_encoding("UTF-8")
      html.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
    else
      raise "Failed to fetch URL: #{response.status}"
    end
  end

  def clean_html(html)
    # Keep structure but remove non-content elements
    # This preserves headings, paragraphs, lists while removing navigation, scripts, etc.

    # First, remove script and style tags with their content
    cleaned = html.gsub(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi, " ")
    cleaned = cleaned.gsub(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/mi, " ")
    cleaned = cleaned.gsub(/<svg\b[^<]*(?:(?!<\/svg>)<[^<]*)*<\/svg>/mi, " ")

    # Remove navigation, footer, header, aside elements
    %w[nav footer header aside noscript iframe].each do |tag|
      cleaned = cleaned.gsub(/<#{tag}[^>]*>.*?<\/#{tag}>/mi, " ")
    end

    # Convert some structural tags to newlines for better readability
    cleaned = cleaned.gsub(/<\/h[1-6]>/i, "\n\n")
    cleaned = cleaned.gsub(/<\/p>/i, "\n\n")
    cleaned = cleaned.gsub(/<\/li>/i, "\n")
    cleaned = cleaned.gsub(/<br\s*\/?>/i, "\n")

    # Remove all remaining HTML tags
    cleaned = cleaned.gsub(/<[^>]+>/, " ")

    # Clean up whitespace but preserve some structure
    cleaned = cleaned.gsub(/&nbsp;/i, " ")
    cleaned = cleaned.gsub(/\n\s*\n\s*\n/, "\n\n")  # Max 2 consecutive newlines
    cleaned = cleaned.gsub(/[ \t]+/, " ")  # Collapse spaces/tabs
    cleaned = cleaned.strip

    cleaned
  end

  def extract_text_from_image
    return nil unless @job_offer.screenshot.attached?

    configure_ai_client

    image_data = @job_offer.screenshot.download
    base64_image = Base64.strict_encode64(image_data)

    prompt = <<~PROMPT
      Extract all text from this job posting image. Preserve the structure and formatting as much as possible.
      Return the raw text content without any additional commentary.
    PROMPT

    chat = RubyLLM.chat(model: @credential.models[:parser])
    response = chat.add_message({
      role: "user",
      content: [
        { type: "text", text: prompt },
        {
          type: "image",
          source: {
            type: "base64",
            media_type: "image/jpeg",
            data: base64_image
          }
        }
      ]
    })

    # Check if response looks like the input (API returned request instead of result)
    extracted_text = response.content.to_s

    # If the response contains the prompt text or looks like JSON/array structure, it failed
    if extracted_text.include?("Extract all text from this job posting image") ||
       extracted_text.include?('"type":') ||
       extracted_text.include?("base64") ||
       extracted_text.start_with?("[") ||
       extracted_text.length < 50

      Rails.logger.error "Image extraction failed. Response: #{extracted_text[0..200]}..."

      # Check if this provider supports vision
      unless @credential.models[:vision_supported]
        vision_providers = AiCredential::MODELS.select { |_, v| v[:vision_supported] }.keys.join(", ")
        raise "The selected AI provider (#{@credential.provider}) does not support image analysis. Please use a URL instead, or switch to one of these providers in your profile settings: #{vision_providers}."
      end

      raise "Failed to extract text from the image. The AI model may not have processed the image correctly. This can happen if the image is too large, unclear, or if the AI service is temporarily unavailable. Please try using a URL instead, or try again later."
    end

    extracted_text
  end

  def parse_with_ai(text)
    configure_ai_client

    prompt = <<~PROMPT
      Extract job posting details from the text below and return ONLY a JSON object with these exact keys. Replace the placeholders with actual extracted values.

      JSON structure to return:
      - "title": The job title (e.g., "Senior Software Engineer")
      - "company": The company name (e.g., "Google")
      - "location": Job location (e.g., "San Francisco, CA" or "Remote")
      - "skills": Array of technical skills mentioned (e.g., ["Ruby", "Rails", "PostgreSQL"])
      - "requirements": Brief summary of key requirements (2-3 sentences)
      - "summary": Brief job description summary (2-3 sentences)

      Job posting text to analyze:
      ---
      #{text[0..4000]}
      ---

      Return ONLY valid JSON. Example response format:
      {"title": "Senior Developer", "company": "Acme Corp", "location": "Remote", "skills": ["Python", "AWS"], "requirements": "5+ years experience required.", "summary": "Leading engineering team to build cloud solutions."}
    PROMPT

    chat = RubyLLM.chat(model: @credential.models[:parser])
    response = chat.ask(prompt)

    content = response.content.to_s.strip

    # Try to extract JSON from markdown code block if present
    if content =~ /```json\s*(.*?)\s*```/m
      content = $1.strip
    elsif content =~ /```\s*(.*?)\s*```/m
      content = $1.strip
    end

    begin
      result = JSON.parse(content)
    rescue JSON::ParserError => e
      # Try to extract the first valid JSON object
      result = extract_first_json_object(content)

      unless result
        Rails.logger.error "Failed to parse AI response as JSON: #{e.message}"
        Rails.logger.error "Response content: #{response&.content&.to_s&.[](0..1000)}"
        return {
          "title" => "Unknown",
          "company" => "Unknown",
          "location" => "Unknown",
          "skills" => [],
          "requirements" => text[0..1000],
          "summary" => "Unable to parse job details"
        }
      end
    end

    # Ensure all required keys exist
    required_keys = %w[title company location skills requirements summary]
    required_keys.each do |key|
      result[key] = "Unknown" if result[key].nil? || result[key] == ""
    end
    result["skills"] = [] if result["skills"].nil? || !result["skills"].is_a?(Array)

    result
  end
end
