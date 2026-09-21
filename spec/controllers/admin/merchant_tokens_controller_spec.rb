# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MerchantTokensController, type: :controller do
  let(:merchant) { create(:merchant) }

  describe "POST #create" do
    it "requires authentication before issuing a token" do
      expect(Merchants::IssueApiTokenService).not_to receive(:call)

      post :create, params: { merchant_id: merchant.id }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects merchant users before issuing a token" do
      sign_in create(:merchant_user)
      expect(Merchants::IssueApiTokenService).not_to receive(:call)

      post :create, params: { merchant_id: merchant.id }

      expect(response).to redirect_to(root_path)
    end

    it "issues a token for the merchant selected by the route" do
      sign_in create(:admin_user)
      issued_token = { token: "signed-token", expires_at: 24.hours.from_now }
      expect(Merchants::IssueApiTokenService).to receive(:call).with(merchant: merchant)
        .and_return(ServiceResult.success(entity: issued_token))

      post :create, params: { merchant_id: merchant.id, token: "ignored" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end
end
