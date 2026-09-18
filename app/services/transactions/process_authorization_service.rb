# frozen_string_literal: true

module Transactions
  class ProcessAuthorizationService < ApplicationService
    OUTCOMES = %w[approved error]

    def call(authorize_transaction:)
      if authorize_transaction.pending?
        authorize_transaction.update!(status: OUTCOMES.sample)
        NotificationJob.perform_later(authorize_transaction)
      end

      ServiceResult.success(entity: authorize_transaction)
    end
  end
end
