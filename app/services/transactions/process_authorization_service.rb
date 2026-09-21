# frozen_string_literal: true

module Transactions
  class ProcessAuthorizationService < ApplicationService
    OUTCOMES = %w[approved error]

    def call(authorize_transaction:)
      if authorize_transaction.pending?
        transition(authorize_transaction, OUTCOMES.sample)
        NotificationJob.perform_later(authorize_transaction)
      end

      ServiceResult.success(entity: authorize_transaction)
    end

    private

    def transition(authorize_transaction, outcome)
      outcome == "approved" ? authorize_transaction.approve! : authorize_transaction.mark_failed!
    end
  end
end
