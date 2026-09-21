# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Transactions dashboard", type: :feature do
  scenario "a merchant only sees their own transactions" do
    merchant = create(:merchant)
    create(:authorize_transaction, merchant: merchant, customer_email: "own@example.com")
    create(:authorize_transaction, customer_email: "other@example.com")

    sign_in merchant.merchant_user
    visit transactions_path

    expect(page).to have_content("own@example.com")
    expect(page).not_to have_content("other@example.com")
  end

  scenario "an admin sees every merchant's transactions" do
    merchant_a = create(:merchant)
    merchant_b = create(:merchant)
    create(:authorize_transaction, merchant: merchant_a, customer_email: "a@example.com")
    create(:authorize_transaction, merchant: merchant_b, customer_email: "b@example.com")

    sign_in create(:admin_user)
    visit transactions_path

    expect(page).to have_content("a@example.com")
    expect(page).to have_content("b@example.com")
  end

  scenario "viewing a transaction's detail page" do
    merchant = create(:merchant)
    transaction = create(:authorize_transaction, merchant: merchant)

    sign_in merchant.merchant_user
    visit transactions_path
    click_link "View"

    expect(page).to have_content(transaction.uuid)
    expect(page).to have_content(transaction.status)
  end
end
