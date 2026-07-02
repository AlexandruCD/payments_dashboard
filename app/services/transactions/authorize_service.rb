# frozen_string_literal: true

module Transactions
  class AuthorizeService
    def self.call(merchant:, params:)
      new(merchant: merchant, params: params).call
    end

    def initialize(merchant:, params:)
      @merchant = merchant
      @params = params
    end

    def call
      transaction = AuthorizeTransaction.new(
        merchant: @merchant,
        amount: @params[:amount],
        customer_email: @params[:customer_email],
        customer_phone: @params[:customer_phone],
        notification_url: @params[:notification_url]
      )
      TransactionProcessingJob.perform_later(transaction) if transaction.save
      transaction
    end
  end
end
