# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionPresenter do
  let(:transaction) { create(:authorize_transaction, amount: 100, status: "approved") }
  subject(:presenter) { described_class.new(transaction) }

  it "delegates basic attributes" do
    expect(presenter.uuid).to eq(transaction.uuid)
    expect(presenter.status).to eq("approved")
  end

  describe "#type_label" do
    it "strips the Transaction suffix" do
      expect(presenter.type_label).to eq("Authorize")
    end
  end

  describe "#formatted_amount" do
    it "formats the amount as currency" do
      expect(presenter.formatted_amount).to eq("$100.00")
    end

    it "returns an em dash when amount is nil" do
      void = create(:void_transaction)
      expect(described_class.new(void).formatted_amount).to eq("—")
    end
  end

  describe "#status_badge_class" do
    it "maps known statuses to badge classes" do
      expect(presenter.status_badge_class).to eq("bg-success")
    end

    it "falls back to bg-secondary for unknown statuses" do
      transaction.status = "mystery"
      expect(presenter.status_badge_class).to eq("bg-secondary")
    end
  end

  describe "#referenced_uuid" do
    it "returns nil when there is no referenced transaction" do
      expect(presenter.referenced_uuid).to be_nil
    end

    it "returns the referenced transaction's uuid" do
      capture = create(:capture_transaction)
      expect(described_class.new(capture).referenced_uuid).to eq(capture.referenced_transaction.uuid)
    end
  end
end
