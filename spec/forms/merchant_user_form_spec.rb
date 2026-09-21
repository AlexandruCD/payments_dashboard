# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantUserForm do
  let(:merchant) { create(:merchant) }
  let(:valid_attributes) { { email: "login@example.com", password: "password123" } }

  describe "#save" do
    it "creates a login for an existing merchant" do
      form = described_class.new(merchant: merchant, attributes: valid_attributes)

      expect { form.save }.to change(MerchantUser, :count).by(1)
      expect(form.merchant_user.merchant).to eq(merchant)
    end

    it "does not create a login for an unpersisted merchant" do
      form = described_class.new(merchant: build(:merchant), attributes: valid_attributes)

      expect { form.save }.not_to change(MerchantUser, :count)
      expect(form.errors[:merchant]).to include("must exist")
    end

    it "does not create a second login for the same merchant" do
      create(:merchant_user, merchant: merchant)
      form = described_class.new(merchant: merchant, attributes: valid_attributes)

      expect { form.save }.not_to change(MerchantUser, :count)
      expect(form.errors[:merchant]).to include("already has a UI login")
    end

    it "keeps the merchant available when user validation fails" do
      form = described_class.new(merchant: merchant, attributes: valid_attributes.merge(email: "invalid"))

      expect(form.save).to be false
      expect(merchant.reload).to be_persisted
      expect(merchant.merchant_user).to be_nil
    end
  end
end
