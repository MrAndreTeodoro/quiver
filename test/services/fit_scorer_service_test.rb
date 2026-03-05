require "test_helper"

class FitScorerServiceTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @profile = Profile.instance
    @credential = @profile.ai_credentials.find_or_initialize_by(provider: "anthropic")

    # Ensure credential has valid API key
    if @credential.api_key.blank? || @credential.api_key.include?("your_key")
      flunk "No valid API key found in database. Please set a real ANTHROPIC_API_KEY first."
    end
  end

  test "API key is configured" do
    assert @credential.api_key.present?, "API key should be present"
    assert @credential.api_key.length > 50, "API key should be a real key (108 chars)"
    refute @credential.api_key.include?("your_key"), "Should not be a placeholder"

    puts "\n✓ API Key verified: #{@credential.masked_api_key}"
    puts "  Model: #{@credential.models[:scorer]}"
  end

  test "profile has content for scoring" do
    assert @profile.content.present?, "Profile should have content"
    assert @profile.content.length > 1000, "Profile should have substantial content"

    puts "\n✓ Profile content: #{@profile.content.length} characters"
    puts "  Name: #{@profile.name}"
  end

  test "can score a parsed job offer" do
    skip "No valid API key" unless @credential.api_key.present? && @credential.api_key.length > 50
    skip "No profile content" unless @profile.content.present?

    # Create a job offer with parsed data
    job_offer = JobOffer.create!(
      url: "https://example.com/job",
      source_type: "url",
      status: "parsed",
      parsed_title: "Senior Ruby on Rails Developer",
      parsed_company: "TechCorp Inc.",
      parsed_location: "Remote",
      parsed_skills: [ "Ruby", "Rails", "PostgreSQL", "Redis", "Docker", "Kubernetes" ].to_json,
      parsed_requirements: "5+ years of Ruby on Rails experience. Strong knowledge of PostgreSQL and Redis. Experience with cloud infrastructure.",
      parsed_summary: "Looking for a senior developer to lead our backend team and build scalable web applications."
    )

    puts "\nScoring job offer:"
    puts "  Title: #{job_offer.parsed_title}"
    puts "  Company: #{job_offer.parsed_company}"
    puts "  Skills: #{job_offer.parsed_skills_array.join(', ')}"

    service = FitScorerService.new(job_offer)

    begin
      result = service.call

      puts "\n✓ Scoring complete!"
      puts "  Score: #{result.fit_score}/100"
      puts "  Status: #{result.status}"
      puts "  Threshold: #{JobOffer::FIT_THRESHOLD}"

      assert result.fit_score.present?, "Should have a fit score"
      assert result.fit_score.is_a?(Numeric), "Score should be numeric"
      assert result.fit_score >= 0 && result.fit_score <= 100, "Score should be 0-100"
      assert result.fit_reasoning.present?, "Should have reasoning"

      strengths = JSON.parse(result.fit_strengths) rescue []
      gaps = JSON.parse(result.fit_gaps) rescue []

      puts "  Strengths (#{strengths.length}): #{strengths.join(', ')}"
      puts "  Gaps (#{gaps.length}): #{gaps.join(', ')}"

    rescue => e
      puts "\n✗ Scoring failed: #{e.message}"
      puts e.backtrace.first(5)
      flunk "Scoring failed: #{e.message}"
    end
  end
end
