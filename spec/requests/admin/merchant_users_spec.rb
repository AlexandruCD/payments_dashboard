# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin merchant users", type: :request do
  let(:merchant) { create(:merchant) }
  let(:valid_params) do
    { merchant_user_form: { email: "login@example.com", password: "password123" } }
  end

  it "requires a signed-in user" do
    post admin_merchant_merchant_user_path(merchant), params: valid_params

    expect(response).to redirect_to(new_user_session_path)
  end

  it "denies merchant users" do
    sign_in create(:merchant_user)

    post admin_merchant_merchant_user_path(merchant), params: valid_params

    expect(response).to redirect_to(root_path)
  end

  it "creates a UI login for the merchant" do
    sign_in create(:admin_user)

    expect { post admin_merchant_merchant_user_path(merchant), params: valid_params }
      .to change(MerchantUser, :count).by(1)

    expect(response).to redirect_to(admin_merchant_path(merchant))
    expect(merchant.reload.merchant_user.email).to eq("login@example.com")
  end

  it "renders the merchant page when the login is invalid" do
    sign_in create(:admin_user)

    post admin_merchant_merchant_user_path(merchant),
         params: { merchant_user_form: { email: "invalid", password: "password123" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(merchant.reload.merchant_user).to be_nil
    expect(response.body).to include("Email is invalid")
  end

  it "does not create a second login" do
    create(:merchant_user, merchant: merchant)
    sign_in create(:admin_user)

    expect { post admin_merchant_merchant_user_path(merchant), params: valid_params }
      .not_to change(MerchantUser, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Merchant already has a UI login")
  end
end
