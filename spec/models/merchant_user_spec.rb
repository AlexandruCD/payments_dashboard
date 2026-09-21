# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantUser, type: :model do
  subject(:merchant_user) { build(:merchant_user) }

  it { is_expected.to have_one(:merchant).with_foreign_key(:user_id).inverse_of(:merchant_user) }

  it "uses the MerchantUser STI type" do
    merchant_user.save!

    expect(User.find(merchant_user.id)).to be_a(described_class)
  end

  it "exposes only the merchant role" do
    expect(merchant_user).to be_merchant
    expect(merchant_user).not_to be_admin
  end

  it "may temporarily exist without a merchant" do
    expect(merchant_user).to be_valid
    expect { merchant_user.save! }.to change(described_class, :count).by(1)
    expect(merchant_user.merchant).to be_nil
  end
end
