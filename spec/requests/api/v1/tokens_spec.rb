# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Removed API token endpoint", type: :request do
  it "does not accept password-based token issuance" do
    post "/api/v1/tokens", params: { email: "merchant@example.com", password: "password123" }

    expect(response).to have_http_status(:not_found)
  end
end
