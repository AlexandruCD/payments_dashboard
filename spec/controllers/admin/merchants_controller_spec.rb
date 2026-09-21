# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MerchantsController, type: :controller do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  describe "POST #create" do
    it "delegates permitted attributes to the merchant form" do
      merchant = build_stubbed(:merchant)
      form = instance_double(MerchantForm, save: true, merchant: merchant)
      expect(MerchantForm).to receive(:new) do |attributes|
        expect(attributes.to_h.symbolize_keys).to eq(
          name: "Acme", email: "merchant@example.com", status: "active"
        )
        form
      end

      post :create, params: {
        merchant_form: {
          name: "Acme", email: "merchant@example.com", status: "active", unexpected: "ignored"
        }
      }

      expect(response).to redirect_to(admin_merchant_path(merchant))
    end
  end

  describe "PATCH #update" do
    it "delegates permitted attributes to the update service" do
      merchant = create(:merchant)
      expected_merchant = merchant
      result = ServiceResult.success(entity: merchant)
      expect(Merchants::UpdateService).to receive(:call) do |merchant:, params:|
        expect(merchant).to eq(expected_merchant)
        expect(params.to_h.symbolize_keys).to eq(name: "New name", status: "inactive")
        result
      end

      patch :update, params: {
        id: merchant.id,
        merchant: { name: "New name", status: "inactive", unexpected: "ignored" }
      }

      expect(response).to redirect_to(admin_merchant_path(merchant))
    end

    it "renders edit when the service fails" do
      merchant = create(:merchant)
      result = ServiceResult.failure(
        entity: merchant,
        errors: [ { attribute: :email, code: :invalid, message: "Email is invalid" } ]
      )
      allow(Merchants::UpdateService).to receive(:call).and_return(result)

      patch :update, params: { id: merchant.id, merchant: { email: "invalid" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
