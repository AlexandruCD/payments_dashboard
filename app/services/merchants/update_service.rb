# frozen_string_literal: true

module Merchants
  class UpdateService < ApplicationService
    STATUS_EVENTS = {
      "active" => :activate,
      "inactive" => :deactivate
    }.freeze

    def call(merchant:, params:)
      merchant.assign_attributes(params.except(:status))
      return validation_failure(merchant) unless transition_status(merchant, params[:status])
      return ServiceResult.success(entity: merchant) if merchant.save

      validation_failure(merchant)
    end

    private

    def transition_status(merchant, requested_status)
      return true if requested_status.blank? || requested_status == merchant.status

      event = STATUS_EVENTS[requested_status]
      if event && merchant.public_send(event)
        true
      else
        merchant.errors.add(:status, :inclusion, value: requested_status)
        false
      end
    end
  end
end
