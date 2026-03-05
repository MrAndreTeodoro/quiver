require "fileutils"

class ExportService
  def initialize(application)
    @application = application
    @job_offer = application.job_offer
  end

  def call
    # Create exports directory if needed
    exports_dir = Rails.root.join("storage", "exports")
    FileUtils.mkdir_p(exports_dir)

    # Build file slug
    slug = build_slug
    date = Date.current.strftime("%Y%m%d")

    # Generate file paths
    base_path = exports_dir.join("#{slug}_#{date}")

    # Export CV
    cv_md_path = "#{base_path}_cv.md"
    cv_docx_path = "#{base_path}_cv.docx"
    cv_pdf_path = "#{base_path}_cv.pdf"

    write_markdown(@application.cv_markdown, cv_md_path)
    MarkdownToDocxService.new(@application.cv_markdown, cv_docx_path).call
    MarkdownToPdfService.new(@application.cv_markdown, cv_pdf_path).call

    # Export Cover Letter
    cover_letter_md_path = "#{base_path}_cover_letter.md"
    cover_letter_docx_path = "#{base_path}_cover_letter.docx"
    cover_letter_pdf_path = "#{base_path}_cover_letter.pdf"

    write_markdown(@application.cover_letter_markdown, cover_letter_md_path)
    MarkdownToDocxService.new(@application.cover_letter_markdown, cover_letter_docx_path).call
    MarkdownToPdfService.new(@application.cover_letter_markdown, cover_letter_pdf_path).call

    # Update application with file paths
    @application.update!(
      cv_md_path: cv_md_path,
      cv_docx_path: cv_docx_path,
      cv_pdf_path: cv_pdf_path,
      cover_letter_md_path: cover_letter_md_path,
      cover_letter_docx_path: cover_letter_docx_path,
      cover_letter_pdf_path: cover_letter_pdf_path
    )

    @application
  rescue => e
    Rails.logger.error "ExportService failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def build_slug
    company = @job_offer.parsed_company.to_s.parameterize
    title = @job_offer.parsed_title.to_s.parameterize

    # Combine and limit length
    parts = [ company, title ].reject(&:blank?)
    parts.join("_").downcase[0..50]
  end

  def write_markdown(content, path)
    File.write(path, content)
  end
end
