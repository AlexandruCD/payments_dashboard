# frozen_string_literal: true

module Transactions
  class CreateRefundService < ApplicationService
    include Persistable

    def call(merchant:, params:)
      ActiveRecord::Base.transaction do
        referenced_capture = CaptureTransaction.find_by(
          uuid: params[:referenced_transaction_uuid], merchant: merchant
        )

        transaction = RefundTransaction.new(
          merchant: merchant,
          amount: params[:amount],
          customer_email: params[:customer_email] || referenced_capture&.customer_email,
          customer_phone: params[:customer_phone] || referenced_capture&.customer_phone,
          referenced_transaction: referenced_capture,
          status: "approved"
        )

        result = persist_or_error(transaction)
        referenced_capture.update!(status: "refunded") if result.success? && referenced_capture

        result
      end
    end
  end
end
