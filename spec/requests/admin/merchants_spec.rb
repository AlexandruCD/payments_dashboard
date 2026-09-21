# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Merchants", type: :request do
  let(:admin) { create(:admin_user) }
  let(:merchant_user) { create(:merchant_user) }

  describe "GET /admin/merchants" do
    it "redirects non-admins" do
      sign_in merchant_user
      get admin_merchants_path
      expect(response).to redirect_to(root_path)
    end

    it "is accessible to admins" do
      create(:merchant)
      sign_in admin
      get admin_merchants_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/merchants" do
    before { sign_in admin }

    let(:valid_params) do
      {
        merchant_form: { name: "Acme", description: "Retail", email: "acme@example.com", status: "active" }
      }
    end

    it "creates a merchant without a user" do
      expect { post admin_merchants_path, params: valid_params }
        .to change(Merchant, :count).by(1).and change(User, :count).by(0)

      expect(response).to redirect_to(admin_merchant_path(Merchant.last))
    end

    it "re-renders the form when invalid" do
      post admin_merchants_path, params: { merchant_form: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/merchants/:id" do
    before { sign_in admin }

    it "updates the merchant" do
      merchant = create(:merchant)
      patch admin_merchant_path(merchant), params: { merchant: { name: "New Name" } }
      expect(merchant.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /admin/merchants/:id" do
    before { sign_in admin }

    it "deletes a merchant with no transactions" do
      merchant = create(:merchant)
      expect { delete admin_merchant_path(merchant) }.to change(Merchant, :count).by(-1)
    end

    it "does not delete a merchant with transactions" do
      merchant = create(:merchant)
      create(:authorize_transaction, merchant: merchant)
      expect { delete admin_merchant_path(merchant) }.not_to change(Merchant, :count)
    end
  end
end
