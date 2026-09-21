# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser, type: :model do
  subject(:admin_user) { build(:admin_user) }

  it "uses the AdminUser STI type" do
    admin_user.save!

    expect(User.find(admin_user.id)).to be_a(described_class)
  end

  it "exposes only the admin role" do
    expect(admin_user).to be_admin
    expect(admin_user).not_to be_merchant
  end

  it "does not expose the merchant association" do
    expect(admin_user).not_to respond_to(:merchant)
  end
end
