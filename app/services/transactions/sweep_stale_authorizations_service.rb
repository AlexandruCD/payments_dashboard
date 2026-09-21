# frozen_string_literal: true

module Transactions
  class SweepStaleAuthorizationsService < ApplicationService
    # Processing normally settles immediately; an hour pending indicates a failed job.
    STALE_AFTER = 1.hour

    def call
      AuthorizeTransaction.pending.where(created_at: ..STALE_AFTER.ago).find_each do |authorize_transaction|
        authorize_transaction.mark_failed!
        NotificationJob.perform_later(authorize_transaction)
      end

      ServiceResult.success(entity: nil)
    end
  end
end
