class JobOffer < ApplicationRecord
  has_one :application, dependent: :destroy
  has_one_attached :screenshot

  FIT_THRESHOLD = 65.0

  enum :status, {
    pending:   "pending",
    parsed:    "parsed",
    scored:    "scored",
    generated: "generated",
    skipped:   "skipped"
  }

  enum :source_type, {
    url:   "url",
    image: "image"
  }

  def above_threshold?
    fit_score.present? && fit_score >= FIT_THRESHOLD
  end

  def parsed_skills_array
    JSON.parse(parsed_skills || "[]")
  rescue JSON::ParserError
    []
  end

  def fit_strengths_array
    JSON.parse(fit_strengths || "[]")
  rescue JSON::ParserError
    []
  end

  def fit_gaps_array
    JSON.parse(fit_gaps || "[]")
  rescue JSON::ParserError
    []
  end
end
