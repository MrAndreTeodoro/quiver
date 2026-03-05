class JobOffersController < ApplicationController
  before_action :set_job_offer, only: [ :show, :destroy, :parse, :score, :generate ]

  def index
    @job_offers = JobOffer.includes(:application).order(created_at: :desc)
  end

  def new
    @job_offer = JobOffer.new
  end

  def create
    @job_offer = JobOffer.new(job_offer_params)
    @job_offer.status = "pending"

    if @job_offer.save
      # Attach screenshot if provided
      if params[:job_offer][:screenshot].present?
        @job_offer.screenshot.attach(params[:job_offer][:screenshot])
      end

      # Automatically parse and score
      begin
        JobParserService.new(@job_offer).call
        FitScorerService.new(@job_offer).call
        redirect_to @job_offer, notice: "Job offer analyzed successfully."
      rescue => e
        redirect_to @job_offer, alert: "Job offer saved but analysis failed: #{e.message}"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @job_offer.destroy
    redirect_to job_offers_url, notice: "Job offer deleted."
  end

  def parse
    JobParserService.new(@job_offer).call
    redirect_to @job_offer, notice: "Job offer re-parsed."
  rescue => e
    redirect_to @job_offer, alert: "Re-parsing failed: #{e.message}"
  end

  def score
    FitScorerService.new(@job_offer).call
    redirect_to @job_offer, notice: "Fit score updated."
  rescue => e
    redirect_to @job_offer, alert: "Scoring failed: #{e.message}"
  end

  def generate
    unless @job_offer.above_threshold?
      redirect_to @job_offer, alert: "Job offer is below the fit threshold (#{JobOffer::FIT_THRESHOLD})"
      return
    end

    DocumentGeneratorService.new(@job_offer).call
    redirect_to @job_offer, notice: "Documents generated successfully."
  rescue => e
    redirect_to @job_offer, alert: "Document generation failed: #{e.message}"
  end

  private

  def set_job_offer
    @job_offer = JobOffer.find(params[:id])
  end

  def job_offer_params
    params.require(:job_offer).permit(:url, :source_type)
  end
end
