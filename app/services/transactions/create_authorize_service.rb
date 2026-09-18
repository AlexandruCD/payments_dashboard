# frozen_string_literal: true

module Transactions
  class CreateAuthorizeService < ApplicationService
    def call(merchant:, params:)
      transaction = AuthorizeTransaction.new(
        merchant: merchant,
        amount: params[:amount],
        customer_email: params[:customer_email],
        customer_phone: params[:customer_phone],
        notification_url: params[:notification_url]
      )
      return validation_failure(transaction) unless transaction.save

      TransactionProcessingJob.perform_later(transaction)
      ServiceResult.success(entity: transaction)
    end
  end
end
