# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tokens", type: :request do
  let(:merchant) { create(:merchant, password: "secret123") }

  describe "POST /api/v1/tokens" do
    it "returns a JWT for valid credentials" do
      post "/api/v1/tokens", params: { email: merchant.email, password: "secret123" }

      expect(response).to have_http_status(:created)
      token = response.parsed_body["token"]
      expect(token).to be_present
      expect(JsonWebToken.decode(token)[:merchant_id]).to eq(merchant.id)
    end

    it "returns unauthorized for a wrong password" do
      post "/api/v1/tokens", params: { email: merchant.email, password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for an unknown email" do
      post "/api/v1/tokens", params: { email: "nobody@example.com", password: "secret123" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "issues a token even when the merchant is inactive" do
      merchant.update!(status: "inactive")
      post "/api/v1/tokens", params: { email: merchant.email, password: "secret123" }
      expect(response).to have_http_status(:created)
    end

    it "supports XML requests and responses" do
      xml_body = { email: merchant.email, password: "secret123" }.to_xml(root: "token")
      post "/api/v1/tokens", params: xml_body,
                              headers: { "Content-Type" => "application/xml", "Accept" => "application/xml" }

      expect(response).to have_http_status(:created)
      expect(Hash.from_xml(response.body)["hash"]["token"]).to be_present
    end
  end
end
