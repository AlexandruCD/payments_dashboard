# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TransactionPresenter do
  it "exposes only API fields, keeping the original amount and STI type" do
    transaction = build_stubbed(:authorize_transaction, uuid: "transaction-uuid", amount: "12.34",
                                status: "pending", customer_email: "buyer@example.com", customer_phone: "+15555550100")

    expect(described_class.new(transaction).to_h).to eq(
      uuid: "transaction-uuid", type: "AuthorizeTransaction", status: "pending",
      amount: BigDecimal("12.34"), customer_email: "buyer@example.com", customer_phone: "+15555550100"
    )
  end

  it "preserves nil amounts and customer fields on error records" do
    transaction = build_stubbed(:void_transaction, status: "error", customer_email: nil, customer_phone: nil)

    expect(described_class.new(transaction).to_h).to include(
      type: "VoidTransaction", status: "error", amount: nil, customer_email: nil, customer_phone: nil
    )
  end
end
