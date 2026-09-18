# frozen_string_literal: true

# Scheduled through config/recurring.yml in production.
class StaleAuthorizationSweeperJob < ApplicationJob
  queue_as :default

  def perform
    Transactions::SweepStaleAuthorizationsService.call
  end
end
