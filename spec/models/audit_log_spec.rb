# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLog, type: :model do
  subject(:audit_log) { build(:audit_log) }

  describe "associations" do
    it { is_expected.to belong_to(:auditable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
  end

  it "can belong to any auditable model" do
    transaction = create(:authorize_transaction)
    log = create(:audit_log, auditable: transaction)
    expect(log.auditable).to eq(transaction)
  end
end
