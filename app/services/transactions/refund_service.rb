# frozen_string_literal: true

module Transactions
  class RefundService
    include Persistable

    def self.call(merchant:, params:)
      new(merchant: merchant, params: params).call
    end

    def initialize(merchant:, params:)
      @merchant = merchant
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        transaction = RefundTransaction.new(
          merchant: @merchant,
          amount: @params[:amount],
          customer_email: @params[:customer_email] || referenced_capture&.customer_email,
          customer_phone: @params[:customer_phone] || referenced_capture&.customer_phone,
          referenced_transaction: referenced_capture,
          status: "approved"
        )

        persist_or_error(transaction)
        referenced_capture.update!(status: "refunded") if transaction.approved? && referenced_capture

        transaction
      end
    end

    private

    # Scoped to the calling merchant, so one merchant can't refund another's capture.
    def referenced_capture
      @referenced_capture ||= CaptureTransaction.find_by(
        uuid: @params[:referenced_transaction_uuid], merchant: @merchant
      )
    end
  end
end
