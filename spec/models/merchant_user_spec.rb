# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantUser, type: :model do
  subject(:merchant_user) { build(:merchant_user) }

  it { is_expected.to belong_to(:merchant).inverse_of(:merchant_user) }

  it "uses the MerchantUser STI type" do
    merchant_user.save!

    expect(User.find(merchant_user.id)).to be_a(described_class)
  end

  it "exposes only the merchant role" do
    expect(merchant_user).to be_merchant
    expect(merchant_user).not_to be_admin
  end

  it "requires a persisted merchant" do
    merchant_user.merchant = nil

    expect(merchant_user).not_to be_valid
    expect(merchant_user.errors[:merchant]).to be_present
  end
end
