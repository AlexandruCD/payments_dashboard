# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Authentication", type: :feature do
  let(:merchant) { create(:merchant, :with_merchant_user) }

  scenario "an admin signs in through the shared User session" do
    admin = create(:admin_user)

    visit new_user_session_path
    fill_in "Email", with: admin.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_content("Signed in successfully")
    expect(page).to have_link("Merchants")
  end

  scenario "signing in with valid credentials" do
    visit new_user_session_path
    fill_in "Email", with: merchant.merchant_user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_content("Signed in successfully")
    expect(page).to have_content("Transactions")
  end

  scenario "signing in with invalid credentials shows an error" do
    visit new_user_session_path
    fill_in "Email", with: merchant.merchant_user.email
    fill_in "Password", with: "wrong-password"
    click_button "Sign in"

    expect(page).to have_content("Invalid email or password")
    expect(current_path).to eq(new_user_session_path)
  end

  scenario "visiting a protected page while signed out redirects to sign in" do
    visit transactions_path
    expect(current_path).to eq(new_user_session_path)
  end

  scenario "signing out" do
    visit new_user_session_path
    fill_in "Email", with: merchant.merchant_user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    click_button "Sign out"

    expect(page).to have_content("Signed out successfully")
    expect(page).to have_link("Sign in")
  end
end
