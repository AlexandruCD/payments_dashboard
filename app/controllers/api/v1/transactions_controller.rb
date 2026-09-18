# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < Api::BaseController
      include JwtAuthenticatable

      def create
        result = Transactions::CreateTransactionService.call(merchant: current_merchant, params: transaction_params)
        transaction = result.entity

        # Failed follow-up submissions are still created as error records.
        if transaction.nil?
          render_payload({ error: result.errors.first[:message] }, status: :unprocessable_content)
        elsif transaction.persisted?
          render_payload(Api::V1::TransactionPresenter.new(transaction).to_h, status: :created)
        else
          render_payload({ errors: result.errors.map { |error| error[:message] } }, status: :unprocessable_content)
        end
      end

      private

      # :status is deliberately not permitted — the API never accepts a client-supplied status.
      def transaction_params
        params.permit(:type, :amount, :customer_email, :customer_phone, :notification_url,
                       :referenced_transaction_uuid)
      end
    end
  end
end
