# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TransactionsController, type: :controller do
  let(:merchant) { create(:merchant) }

  before do
    request.headers["Authorization"] = "Bearer #{JsonWebToken.encode(merchant_id: merchant.id)}"
  end

  describe "POST #create" do
    it "delegates permitted parameters for the authenticated merchant" do
      transaction = build_stubbed(:authorize_transaction, merchant: merchant)
      result = ServiceResult.success(entity: transaction)

      expect(Transactions::CreateTransactionService).to receive(:call) do |merchant:, params:|
        expect(merchant).to eq(self.merchant)
        expect(params.to_h.symbolize_keys).to eq(
          type: "authorize",
          amount: "100",
          customer_email: "buyer@example.com"
        )
        result
      end

      post :create, params: {
        type: "authorize", amount: 100, customer_email: "buyer@example.com",
        status: "approved", unexpected: "ignored"
      }

      expect(response).to have_http_status(:created)
    end

    it "uses the API presenter for a persisted transaction" do
      transaction = build_stubbed(:authorize_transaction, merchant: merchant)
      payload = { uuid: transaction.uuid, status: "pending" }
      presenter = instance_double(Api::V1::TransactionPresenter, to_h: payload)
      allow(Transactions::CreateTransactionService).to receive(:call)
        .and_return(ServiceResult.success(entity: transaction))
      expect(Api::V1::TransactionPresenter).to receive(:new).with(transaction).and_return(presenter)

      post :create, params: { type: "authorize" }

      expect(response.parsed_body).to eq("uuid" => transaction.uuid, "status" => "pending")
    end

    it "returns one error for an unresolved transaction type" do
      result = ServiceResult.failure(
        entity: nil,
        errors: [ { attribute: :type, code: :invalid, message: "invalid transaction type" } ]
      )
      allow(Transactions::CreateTransactionService).to receive(:call).and_return(result)

      post :create, params: { type: "unknown" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "invalid transaction type")
    end

    it "returns validation errors for an unsaved transaction" do
      transaction = build(:authorize_transaction, merchant: merchant)
      result = ServiceResult.failure(
        entity: transaction,
        errors: [ { attribute: :amount, code: :blank, message: "Amount can't be blank" } ]
      )
      allow(Transactions::CreateTransactionService).to receive(:call).and_return(result)

      post :create, params: { type: "authorize" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [ "Amount can't be blank" ])
    end

    it "renders persisted error transactions as created" do
      transaction = build_stubbed(:capture_transaction, merchant: merchant, status: "error")
      result = ServiceResult.failure(
        entity: transaction,
        errors: [ { attribute: :base, code: :invalid, message: "Invalid capture" } ]
      )
      allow(Transactions::CreateTransactionService).to receive(:call).and_return(result)

      post :create, params: { type: "capture" }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("error")
    end
  end
end
