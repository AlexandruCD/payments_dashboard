# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Transactions", type: :request do
  let(:merchant) { create(:merchant) }
  let(:token) { JsonWebToken.encode(merchant_id: merchant.id) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  describe "authentication" do
    it "rejects requests without a token" do
      post "/api/v1/transactions", params: { type: "authorize" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a garbage token" do
      post "/api/v1/transactions", params: { type: "authorize" },
                                    headers: { "Authorization" => "Bearer garbage" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an inactive merchant" do
      merchant.update!(status: "inactive")
      post "/api/v1/transactions", params: { type: "authorize" }, headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/transactions (authorize)" do
    let(:valid_params) do
      {
        type: "authorize",
        amount: 100,
        customer_email: "customer@example.com",
        customer_phone: "+15555550100",
        notification_url: "https://merchant.example.com/notify"
      }
    end

    it "creates a pending authorize transaction" do
      post "/api/v1/transactions", params: valid_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")
      expect(response.parsed_body["type"]).to eq("AuthorizeTransaction")
    end

    it "ignores a client-supplied status" do
      post "/api/v1/transactions", params: valid_params.merge(status: "approved"), headers: auth_headers
      expect(response.parsed_body["status"]).to eq("pending")
    end

    it "returns unprocessable_entity with errors when invalid" do
      post "/api/v1/transactions", params: valid_params.merge(notification_url: nil), headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "rejects an unknown transaction type" do
      post "/api/v1/transactions", params: { type: "bogus" }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/transactions (capture)" do
    let(:authorize_transaction) do
      create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved")
    end

    it "creates an approved capture transaction and captures the authorization" do
      post "/api/v1/transactions", params: {
        type: "capture", amount: 40, referenced_transaction_uuid: authorize_transaction.uuid
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(authorize_transaction.reload.status).to eq("captured")
    end

    it "persists with status error when referencing another merchant's authorization" do
      other_authorize = create(:authorize_transaction, amount: 100, status: "approved")

      post "/api/v1/transactions", params: {
        type: "capture", amount: 40, referenced_transaction_uuid: other_authorize.uuid
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("error")
    end
  end

  describe "POST /api/v1/transactions (refund)" do
    let(:authorize_transaction) do
      create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved")
    end
    let(:capture_transaction) do
      create(:capture_transaction, merchant: merchant, referenced_transaction: authorize_transaction,
                                    amount: 100, status: "approved")
    end

    it "creates an approved refund transaction and refunds the capture" do
      post "/api/v1/transactions", params: {
        type: "refund", amount: 40, referenced_transaction_uuid: capture_transaction.uuid
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(capture_transaction.reload.status).to eq("refunded")
    end
  end

  describe "POST /api/v1/transactions (void)" do
    let(:authorize_transaction) do
      create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved")
    end

    it "creates an approved void transaction and voids the authorization" do
      post "/api/v1/transactions", params: {
        type: "void", referenced_transaction_uuid: authorize_transaction.uuid
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(authorize_transaction.reload.status).to eq("voided")
    end
  end

  describe "XML support" do
    it "accepts an XML request body and responds with XML" do
      xml_body = {
        type: "authorize", amount: 100, customer_email: "customer@example.com",
        notification_url: "https://merchant.example.com/notify"
      }.to_xml(root: "transaction")

      post "/api/v1/transactions", params: xml_body,
                                    headers: auth_headers.merge(
                                      "Content-Type" => "application/xml", "Accept" => "application/xml"
                                    )

      expect(response).to have_http_status(:created)
      expect(Hash.from_xml(response.body)["hash"]["status"]).to eq("pending")
    end
  end
end
