# frozen_string_literal: true

require "rails_helper"

RSpec.describe MerchantRegistrationForm do
  let(:valid_attributes) do
    {
      name: "Acme Corp", description: "Retailer", email: "acme@example.com", status: "active",
      password: "password123", user_email: "acme-login@example.com", user_password: "password123"
    }
  end

  describe "#save" do
    context "with valid attributes" do
      subject(:form) { described_class.new(valid_attributes) }

      it "creates a merchant and its linked user" do
        expect { form.save }.to change(Merchant, :count).by(1).and change(User, :count).by(1)
      end

      it "returns true" do
        expect(form.save).to be true
      end

      it "links the created merchant to the created user" do
        form.save
        expect(form.merchant.user.email).to eq("acme-login@example.com")
        expect(form.merchant.user.role).to eq("merchant")
      end
    end

    context "with missing required fields" do
      subject(:form) { described_class.new(valid_attributes.merge(name: nil)) }

      it "does not create any records" do
        expect { form.save }.not_to change(Merchant, :count)
      end

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when the underlying merchant is invalid" do
      subject(:form) { described_class.new(valid_attributes.merge(email: "not-an-email")) }

      it "rolls back the created user" do
        expect { form.save }.not_to change(User, :count)
      end

      it "returns false and surfaces the underlying validation error" do
        expect(form.save).to be false
        expect(form.errors[:base]).to be_present
      end
    end
  end
end
