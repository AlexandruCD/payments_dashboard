# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < Api::BaseController
      include JwtAuthenticatable

      SERVICES = {
        "authorize" => Transactions::CreateAuthorizeService,
        "capture" => Transactions::CreateCaptureService,
        "refund" => Transactions::CreateRefundService,
        "void" => Transactions::CreateVoidService
      }.freeze

      def create
        service_class = SERVICES[transaction_params[:type]]

        if service_class.nil?
          render_payload({ error: "invalid transaction type" }, status: :unprocessable_content)
          return
        end

        result = service_class.call(merchant: current_merchant, params: transaction_params)

        transaction = result.entity

        # Failed follow-up submissions are still created as error records.
        if transaction.persisted?
          render_payload(transaction_json(transaction), status: :created)
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
