# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable, dependent: :destroy

    after_update :log_status_change, if: :saved_change_to_status?
  end

  private

  def log_status_change
    was, now = saved_change_to_status
    audit_logs.create!(action: "status_changed", details: "#{was} -> #{now}")
  end
end
