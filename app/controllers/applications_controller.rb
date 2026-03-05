class ApplicationsController < ApplicationController
  before_action :set_application, only: [ :show, :update, :download_cv_md, :download_cv_docx, :download_cv_pdf, :download_cover_letter_md, :download_cover_letter_docx, :download_cover_letter_pdf ]

  def show
  end

  def update
    if @application.update(application_params)
      # Auto-set applied_at if status changed to applied
      if @application.application_status == "applied" && @application.applied_at.blank?
        @application.update!(applied_at: Time.current)
      end

      redirect_to @application, notice: "Application updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def download_cv_md
    send_file_or_redirect(@application.cv_md_path, "#{slug}_cv.md", "text/markdown")
  end

  def download_cv_docx
    send_file_or_redirect(@application.cv_docx_path, "#{slug}_cv.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
  end

  def download_cv_pdf
    send_file_or_redirect(@application.cv_pdf_path, "#{slug}_cv.pdf", "application/pdf")
  end

  def download_cover_letter_md
    send_file_or_redirect(@application.cover_letter_md_path, "#{slug}_cover_letter.md", "text/markdown")
  end

  def download_cover_letter_docx
    send_file_or_redirect(@application.cover_letter_docx_path, "#{slug}_cover_letter.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
  end

  def download_cover_letter_pdf
    send_file_or_redirect(@application.cover_letter_pdf_path, "#{slug}_cover_letter.pdf", "application/pdf")
  end

  private

  def set_application
    @application = Application.find(params[:id])
  end

  def application_params
    params.require(:application).permit(:application_status, :applied_at, :notes)
  end

  def slug
    job = @application.job_offer
    company = job.parsed_company.to_s.parameterize
    title = job.parsed_title.to_s.parameterize
    [ company, title ].reject(&:blank?).join("_")[0..30]
  end

  def send_file_or_redirect(file_path, filename, content_type)
    if file_path.blank?
      redirect_to @application, alert: "File not found. Documents may not have been generated yet."
      return
    end

    if File.exist?(file_path)
      send_file file_path, filename: filename, disposition: :attachment, type: content_type
    else
      redirect_to @application, alert: "File not found on disk: #{filename}"
    end
  end
end
