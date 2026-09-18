# frozen_string_literal: true

class TransactionProcessingJob < ApplicationJob
  queue_as :default

  def perform(authorize_transaction)
    Transactions::ProcessAuthorizationService.call(authorize_transaction: authorize_transaction)
  end
end
