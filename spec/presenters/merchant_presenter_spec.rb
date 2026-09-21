# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantPresenter do
  let(:merchant) { create(:merchant, status: "active") }
  subject(:presenter) { described_class.new(merchant) }

  it "delegates basic attributes" do
    expect(presenter.name).to eq(merchant.name)
    expect(presenter.email).to eq(merchant.email)
  end

  describe "#status_badge_class" do
    it "returns bg-success when active" do
      expect(presenter.status_badge_class).to eq("bg-success")
    end

    it "returns bg-secondary when inactive" do
      merchant.status = "inactive"
      expect(presenter.status_badge_class).to eq("bg-secondary")
    end
  end

  describe "#status_label" do
    it "translates the stored status for display" do
      expect(presenter.status_label).to eq("Active")
    end
  end

  describe "#transaction_count" do
    it "counts the merchant's transactions" do
      create(:authorize_transaction, merchant: merchant)
      create(:authorize_transaction, merchant: merchant)
      expect(presenter.transaction_count).to eq(2)
    end
  end
end
