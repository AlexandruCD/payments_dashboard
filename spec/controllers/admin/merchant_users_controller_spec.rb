# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MerchantUsersController, type: :controller do
  let(:merchant) { create(:merchant) }

  before { sign_in create(:admin_user) }

  describe "POST #create" do
    it "delegates permitted credentials and the route merchant to the form" do
      expected_merchant = merchant
      form = instance_double(MerchantUserForm, save: true)
      expect(MerchantUserForm).to receive(:new) do |merchant:, attributes:|
        expect(merchant).to eq(expected_merchant)
        expect(attributes.to_h.symbolize_keys).to eq(
          email: "login@example.com",
          password: "password123"
        )
        form
      end

      post :create, params: {
        merchant_id: merchant.id,
        merchant_user_form: {
          email: "login@example.com", password: "password123", unexpected: "ignored"
        }
      }

      expect(response).to redirect_to(admin_merchant_path(merchant))
    end

    it "returns unprocessable content when the form fails" do
      form = instance_double(MerchantUserForm, save: false)
      allow(MerchantUserForm).to receive(:new).and_return(form)

      post :create, params: {
        merchant_id: merchant.id,
        merchant_user_form: { email: "invalid", password: "password123" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
