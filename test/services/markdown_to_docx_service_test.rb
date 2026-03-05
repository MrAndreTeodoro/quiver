require "test_helper"

class MarkdownToDocxServiceTest < ActiveSupport::TestCase
  test "converts markdown with lists to docx" do
    markdown = <<~MD
      # Senior Developer

      ## Skills
      - Ruby on Rails
      - PostgreSQL
      - JavaScript

      ## Experience
      Senior developer with 5+ years experience.
    MD

    output_path = Rails.root.join("tmp", "test_output.docx").to_s

    service = MarkdownToDocxService.new(markdown, output_path)

    assert_nothing_raised do
      service.call
    end

    assert File.exist?(output_path), "DOCX file should be created"
    assert File.size(output_path) > 0, "DOCX file should not be empty"

    File.delete(output_path) if File.exist?(output_path)

    puts "✓ DOCX generation with lists works!"
  end
end
