# frozen_string_literal: true

module Transactions
  class VoidService
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
        transaction = VoidTransaction.new(
          merchant: @merchant,
          customer_email: @params[:customer_email] || referenced_authorize&.customer_email,
          customer_phone: @params[:customer_phone] || referenced_authorize&.customer_phone,
          referenced_transaction: referenced_authorize,
          status: "approved"
        )

        persist_or_error(transaction)
        referenced_authorize.update!(status: "voided") if transaction.approved? && referenced_authorize

        transaction
      end
    end

    private

    # Scoped to the calling merchant, so one merchant can't void another's authorization.
    def referenced_authorize
      @referenced_authorize ||= AuthorizeTransaction.find_by(
        uuid: @params[:referenced_transaction_uuid], merchant: @merchant
      )
    end
  end
end
