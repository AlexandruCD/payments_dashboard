# frozen_string_literal: true

module Transactions
  class CreateVoidService < ApplicationService
    include Persistable

    def call(merchant:, params:)
      ActiveRecord::Base.transaction do
        referenced_authorize = AuthorizeTransaction.find_by(
          uuid: params[:referenced_transaction_uuid], merchant: merchant
        )

        transaction = VoidTransaction.new(
          merchant: merchant,
          customer_email: params[:customer_email] || referenced_authorize&.customer_email,
          customer_phone: params[:customer_phone] || referenced_authorize&.customer_phone,
          referenced_transaction: referenced_authorize
        )

        result = persist_or_error(transaction)
        referenced_authorize.void! if result.success? && referenced_authorize

        result
      end
    end
  end
end
