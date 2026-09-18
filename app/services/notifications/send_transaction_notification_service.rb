# frozen_string_literal: true

require "net/http"

module Notifications
  class SendTransactionNotificationService < ApplicationService
    def call(authorize_transaction:)
      response = Net::HTTP.post_form(
        URI.parse(authorize_transaction.notification_url),
        "unique_id" => authorize_transaction.uuid,
        "amount" => authorize_transaction.amount.to_s,
        "status" => authorize_transaction.status
      )
      ServiceResult.success(entity: response)
    end
  end
end
