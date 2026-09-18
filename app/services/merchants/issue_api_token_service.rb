# frozen_string_literal: true

module Merchants
  class IssueApiTokenService < ApplicationService
    def call(merchant:)
      expires_at = 24.hours.from_now.change(usec: 0)
      token = JsonWebToken.encode({ merchant_id: merchant.id }, expires_at)

      ServiceResult.success(entity: { token: token, expires_at: expires_at })
    end
  end
end
