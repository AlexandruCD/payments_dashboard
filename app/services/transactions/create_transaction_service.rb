# frozen_string_literal: true

module Transactions
  class CreateTransactionService < ApplicationService
    SERVICES = {
      "authorize" => CreateAuthorizeService,
      "capture" => CreateCaptureService,
      "refund" => CreateRefundService,
      "void" => CreateVoidService
    }.freeze

    def call(merchant:, params:)
      service_class = SERVICES[params[:type]]
      return service_class.call(merchant: merchant, params: params) if service_class

      ServiceResult.failure(
        entity: nil,
        errors: [ { attribute: :type, code: :invalid, message: "invalid transaction type" } ]
      )
    end
  end
end
