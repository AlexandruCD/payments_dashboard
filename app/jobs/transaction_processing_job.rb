# frozen_string_literal: true

class TransactionProcessingJob < ApplicationJob
  queue_as :default

  OUTCOMES = %w[approved error]

  def perform(authorize_transaction)
    return unless authorize_transaction.pending?

    authorize_transaction.update!(status: OUTCOMES.sample)
    NotificationJob.perform_later(authorize_transaction)
  end
end
