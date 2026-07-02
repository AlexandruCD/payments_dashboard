# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < Api::BaseController
      include JwtAuthenticatable

      SERVICES = {
        "authorize" => Transactions::AuthorizeService,
        "capture" => Transactions::CaptureService,
        "refund" => Transactions::RefundService,
        "void" => Transactions::VoidService
      }.freeze

      def create
        service_class = SERVICES[transaction_params[:type]]

        if service_class.nil?
          render_payload({ error: "invalid transaction type" }, status: :unprocessable_content)
          return
        end

        transaction = service_class.call(merchant: current_merchant, params: transaction_params)

        if transaction.persisted?
          render_payload(transaction_json(transaction), status: :created)
        else
          render_payload({ errors: transaction.errors.full_messages }, status: :unprocessable_content)
        end
      end

      private

      # :status is deliberately not permitted — the API never accepts a client-supplied status.
      def transaction_params
        params.permit(:type, :amount, :customer_email, :customer_phone, :notification_url,
                       :referenced_transaction_uuid)
      end

      def transaction_json(transaction)
        {
          uuid: transaction.uuid,
          type: transaction.type,
          status: transaction.status,
          amount: transaction.amount,
          customer_email: transaction.customer_email,
          customer_phone: transaction.customer_phone
        }
      end
    end
  end
end
