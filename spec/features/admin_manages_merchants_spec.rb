# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Admin manages merchants", type: :feature do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  scenario "creating a new merchant" do
    visit admin_merchants_path
    click_link "New Merchant"

    fill_in "Name", with: "Acme Corp"
    fill_in "Description", with: "Retailer"
    fill_in "Email", with: "acme@example.com"
    select "Active", from: "Status"
    click_button "Create Merchant"

    expect(page).to have_content("Merchant created. Add a UI login when needed.")
    expect(page).to have_content("Acme Corp")
    merchant = Merchant.find_by!(email: "acme@example.com")
    expect(merchant.merchant_user).to be_nil

    fill_in "Login email", with: "acme-login@example.com"
    fill_in "Login password", with: "password123"
    click_button "Create UI login"

    expect(page).to have_content("Merchant UI login created.")
    expect(merchant.reload.merchant_user.email).to eq("acme-login@example.com")
  end

  scenario "generating a merchant API token" do
    merchant = create(:merchant)
    visit admin_merchant_path(merchant)
    click_button "Generate API token"

    token = find_field("API token").value
    expect(JsonWebToken.decode(token)[:merchant_id]).to eq(merchant.id)
    expect(page).to have_content("Expires at:")
    click_link "Back to merchant"
    expect(page).not_to have_field("API token")
  end

  scenario "editing a merchant" do
    merchant = create(:merchant, name: "Old Name")
    visit admin_merchants_path

    within("tr", text: "Old Name") { click_link "Edit" }
    fill_in "Name", with: "New Name"
    click_button "Update Merchant"

    expect(page).to have_content("Merchant updated.")
    expect(page).to have_content("New Name")
    expect(merchant.reload.name).to eq("New Name")
  end

  scenario "deleting a merchant with no transactions" do
    create(:merchant, name: "Deletable Co")
    visit admin_merchants_path

    within("tr", text: "Deletable Co") { click_button "Delete" }

    expect(page).to have_content("Merchant deleted.")
    expect(page).not_to have_content("Deletable Co")
  end

  scenario "cannot delete a merchant with transactions" do
    merchant = create(:merchant, name: "Has Transactions Co")
    create(:authorize_transaction, merchant: merchant)
    visit admin_merchants_path

    within("tr", text: "Has Transactions Co") { click_button "Delete" }

    expect(page).to have_content("Has Transactions Co")
    expect(Merchant.exists?(merchant.id)).to be true
  end

  scenario "non-admins cannot access merchant management" do
    sign_out admin
    sign_in create(:merchant_user)

    visit admin_merchants_path

    expect(page).to have_content("You are not authorized to view this page.")
  end
end
