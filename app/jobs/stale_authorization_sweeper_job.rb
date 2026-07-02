# frozen_string_literal: true

# Recurring (config/recurring.yml): AuthorizeTransactions normally settle almost
# instantly via TransactionProcessingJob. Still "pending" after STALE_AFTER means
# something actually went wrong (worker down, job failure), not just a slow processor.
class StaleAuthorizationSweeperJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 1.hour

  def perform
    AuthorizeTransaction.pending.where(created_at: ..STALE_AFTER.ago).find_each do |authorize_transaction|
      authorize_transaction.update!(status: "error")
      NotificationJob.perform_later(authorize_transaction)
    end
  end
end
