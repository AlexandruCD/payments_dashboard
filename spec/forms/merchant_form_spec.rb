# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantForm do
  let(:valid_attributes) do
    { name: "Acme Corp", description: "Retailer", email: "acme@example.com", status: "active" }
  end

  describe "#save" do
    it "creates only a merchant with valid attributes" do
      form = described_class.new(valid_attributes)

      expect { form.save }.to change(Merchant, :count).by(1).and change(User, :count).by(0)
      expect(form.merchant).to be_persisted
    end

    it "returns false and exposes merchant validation errors" do
      form = described_class.new(valid_attributes.merge(email: "not-an-email"))

      expect(form.save).to be false
      expect(form.errors[:base]).to include("Email is invalid")
    end
  end
end
