# frozen_string_literal: true

require "rails_helper"

RSpec.describe Merchants::IssueApiTokenService do
  include ActiveSupport::Testing::TimeHelpers

  it "returns a signed merchant token and its exact 24-hour expiry" do
    merchant = build_stubbed(:merchant)
    freeze_time do
      result = described_class.call(merchant: merchant)
      payload = JsonWebToken.decode(result.entity[:token])

      expect(result).to be_success
      expect(payload[:merchant_id]).to eq(merchant.id)
      expect(result.entity[:expires_at]).to eq(24.hours.from_now)
      expect(payload[:exp]).to eq(result.entity[:expires_at].to_i)

      travel 24.hours + 1.second
      expect { JsonWebToken.decode(result.entity[:token]) }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
