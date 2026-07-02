# frozen_string_literal: true

class NotificationJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, wait: :polynomially_longer, attempts: 5

  def perform(authorize_transaction)
    Net::HTTP.post_form(
      URI.parse(authorize_transaction.notification_url),
      "unique_id" => authorize_transaction.uuid,
      "amount" => authorize_transaction.amount.to_s,
      "status" => authorize_transaction.status
    )
  end
end
