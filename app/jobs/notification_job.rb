# frozen_string_literal: true

require "net/http"

class NotificationJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, wait: :polynomially_longer, attempts: 5

  def perform(authorize_transaction)
    Notifications::SendTransactionNotificationService.call(authorize_transaction: authorize_transaction)
  end
end
