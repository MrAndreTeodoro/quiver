class Application < ApplicationRecord
  belongs_to :job_offer

  enum :application_status, {
    not_applied:  "not_applied",
    applied:      "applied",
    interviewing: "interviewing",
    offer:        "offer",
    rejected:     "rejected",
    withdrawn:    "withdrawn"
  }

  def mark_applied!
    update!(application_status: "applied", applied_at: Time.current)
  end
end
