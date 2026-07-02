# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Admin manages merchants", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  scenario "creating a new merchant" do
    visit admin_merchants_path
    click_link "New Merchant"

    fill_in "Name", with: "Acme Corp"
    fill_in "Description", with: "Retailer"
    fill_in "Email", with: "acme@example.com"
    select "active", from: "Status"
    fill_in "API password", with: "password123"
    fill_in "Login email", with: "acme-login@example.com"
    fill_in "Login password", with: "password123"
    click_button "Create Merchant"

    expect(page).to have_content("Merchant created.")
    expect(page).to have_content("Acme Corp")
    expect(Merchant.find_by(email: "acme@example.com")).to be_present
    expect(User.find_by(email: "acme-login@example.com")).to be_present
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
    sign_in create(:user, :merchant_user)

    visit admin_merchants_path

    expect(page).to have_content("You are not authorized to view this page.")
  end
end
