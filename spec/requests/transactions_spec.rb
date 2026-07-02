# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Transactions", type: :request do
  describe "GET /transactions" do
    it "redirects to sign in when not authenticated" do
      get transactions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "as a merchant user" do
      let(:merchant) { create(:merchant) }
      let(:own_transaction) { create(:authorize_transaction, merchant: merchant) }
      let(:other_transaction) { create(:authorize_transaction) }

      before do
        own_transaction
        other_transaction
        sign_in merchant.user
      end

      it "only shows the merchant's own transactions" do
        get transactions_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(own_transaction.customer_email)
        expect(response.body).not_to include(other_transaction.customer_email)
      end
    end

    context "as an admin user" do
      let(:admin) { create(:user, :admin) }

      before do
        create(:authorize_transaction)
        sign_in admin
      end

      it "shows all transactions" do
        get transactions_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /transactions/:id" do
    let(:merchant) { create(:merchant) }
    let(:transaction) { create(:authorize_transaction, merchant: merchant) }

    it "shows a merchant its own transaction" do
      sign_in merchant.user
      get transaction_path(transaction)
      expect(response).to have_http_status(:ok)
    end

    it "does not let a merchant view another merchant's transaction" do
      other_merchant = create(:merchant)
      sign_in other_merchant.user
      get transaction_path(transaction)
      expect(response).to have_http_status(:not_found)
    end
  end
end
