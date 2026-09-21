# frozen_string_literal: true

require "rails_helper"

RSpec.describe Merchants::UpdateService do
  let(:merchant) { create(:merchant, name: "Old name") }

  it "updates attributes and transitions status together" do
    result = described_class.call(merchant: merchant, params: { name: "New name", status: "inactive" })

    expect(result).to be_success
    expect(merchant.reload).to have_attributes(name: "New name", status: "inactive")
    expect(merchant.audit_logs.last.details).to eq("active -> inactive")
  end

  it "updates attributes without requiring a status parameter" do
    result = described_class.call(merchant: merchant, params: { name: "New name" })

    expect(result).to be_success
    expect(merchant.reload).to have_attributes(name: "New name", status: "active")
  end

  it "returns a failure without persisting an unsupported status or other changes" do
    result = described_class.call(merchant: merchant, params: { name: "New name", status: "suspended" })

    expect(result).to be_failure
    expect(merchant.reload).to have_attributes(name: "Old name", status: "active")
  end

  it "returns model validation errors without persisting changes" do
    result = described_class.call(merchant: merchant, params: { email: "invalid", status: "inactive" })

    expect(result).to be_failure
    expect(result.errors).to include(attribute: :email, code: :invalid, message: "Email is invalid")
    expect(merchant.reload.status).to eq("active")
  end
end
