require "test_helper"

class JsonExtractionTest < ActiveSupport::TestCase
  test "extracts JSON when AI adds text before it" do
    # Simulate the problematic response where AI says "Extract" before the JSON
    raw_response = <<~RESPONSE
      Extracting job details from the posting...

      {"title": "Senior Developer", "company": "TechCorp", "location": "Remote", "skills": ["Ruby", "Rails"], "requirements": "5 years experience", "summary": "Great role"}

      Let me know if you need anything else!
    RESPONSE

    # Simulate the extraction logic
    content = raw_response.strip

    # Try to extract JSON from markdown code block if present
    if content =~ /```json\s*(.*?)\s*```/m
      content = $1.strip
    elsif content =~ /```\s*(.*?)\s*```/m
      content = $1.strip
    end

    # Try to find the first { and last } to extract just the JSON object
    start_idx = content.index("{")
    end_idx = content.rindex("}")

    assert start_idx, "Should find opening brace"
    assert end_idx, "Should find closing brace"

    json_str = content[start_idx..end_idx]
    result = JSON.parse(json_str)

    assert_equal "Senior Developer", result["title"]
    assert_equal "TechCorp", result["company"]
    assert_equal "Remote", result["location"]
    assert result["skills"].is_a?(Array)
    assert_includes result["skills"], "Ruby"

    puts "✓ Successfully extracted JSON from text with extra content"
  end

  test "handles text after JSON object" do
    # This is the exact error scenario - AI returns JSON followed by explanatory text
    raw_response = <<~RESPONSE
      {"title": "Engineer", "company": "Acme", "location": "NYC", "skills": ["Python"], "requirements": "3 years", "summary": "Good job"}
      Job requirements include additional skills that may be relevant.
    RESPONSE

    # Use the same extraction logic as the service
    service = JobParserService.new(JobOffer.new)
    result = service.send(:extract_first_json_object, raw_response)

    assert result, "Should extract JSON even with trailing text"
    assert_equal "Engineer", result["title"]
    assert_equal "Acme", result["company"]

    puts "✓ Successfully extracted JSON with trailing text"
  end

  test "handles markdown-wrapped JSON" do
    raw_response = <<~RESPONSE
      ```json
      {"title": "Engineer", "company": "Acme", "location": "NYC", "skills": ["Python"], "requirements": "3 years", "summary": "Good job"}
      ```
    RESPONSE

    content = raw_response.strip

    if content =~ /```json\s*(.*?)\s*```/m
      content = $1.strip
    elsif content =~ /```\s*(.*?)\s*```/m
      content = $1.strip
    end

    result = JSON.parse(content)
    assert_equal "Engineer", result["title"]
    puts "✓ Successfully parsed markdown-wrapped JSON"
  end

  test "handles plain JSON" do
    raw_response = '{"title": "Manager", "company": "Corp", "location": "SF", "skills": [], "requirements": "Leadership", "summary": "Management role"}'

    content = raw_response.strip
    result = JSON.parse(content)

    assert_equal "Manager", result["title"]
    puts "✓ Successfully parsed plain JSON"
  end
end
