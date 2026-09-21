# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin merchant tokens", type: :request do
  let(:merchant) { create(:merchant) }
  let(:admin) { create(:admin_user) }

  def issued_token
    Nokogiri::HTML(response.body).at_css("textarea#api_token").text.strip
  end

  it "requires a signed-in user" do
    expect(Merchants::IssueApiTokenService).not_to receive(:call)
    post admin_merchant_token_path(merchant)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "denies a merchant user even for their own merchant" do
    sign_in merchant.merchant_user
    expect(Merchants::IssueApiTokenService).not_to receive(:call)
    post admin_merchant_token_path(merchant)

    expect(response).to redirect_to(root_path)
  end

  it "issues a usable token for the route's merchant without caching or retaining it" do
    sign_in admin
    post admin_merchant_token_path(merchant), params: { merchant_id: create(:merchant).id, token: "ignored" }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(Nokogiri::HTML(response.body).at_css('meta[name="turbo-cache-control"]')["content"]).to eq("no-cache")
    token = issued_token
    expect(JsonWebToken.decode(token)[:merchant_id]).to eq(merchant.id)
    expect(flash.to_hash.values.join).not_to include(token)

    get admin_merchant_path(merchant)
    expect(response.body).not_to include(token)

    sign_out admin
    post "/api/v1/transactions", params: {
      type: "authorize", amount: 100, customer_email: "buyer@example.com",
      notification_url: "https://merchant.example.com/notify"
    }, headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:created)
    expect(Transaction.find_by!(uuid: response.parsed_body["uuid"]).merchant).to eq(merchant)
  end

  it "allows admin issuance for inactive merchants but forbids their API submissions" do
    merchant.update!(status: "inactive")
    sign_in admin
    post admin_merchant_token_path(merchant)
    expect(response).to have_http_status(:ok)
    token = issued_token

    post "/api/v1/transactions", params: { type: "authorize" },
                                  headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:forbidden)
  end

  it "returns not found for an unresolved merchant" do
    sign_in admin
    expect(Merchants::IssueApiTokenService).not_to receive(:call)
    post admin_merchant_token_path(merchant_id: 0)

    expect(response).to have_http_status(:not_found)
  end

  it "does not issue tokens through GET" do
    sign_in admin
    get admin_merchant_token_path(merchant)

    expect(response).to have_http_status(:not_found)
  end

  it "rejects a POST without a CSRF token when forgery protection is enabled" do
    sign_in admin
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    expect(Merchants::IssueApiTokenService).not_to receive(:call)

    post admin_merchant_token_path(merchant)

    expect(response).to have_http_status(:unprocessable_content)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
