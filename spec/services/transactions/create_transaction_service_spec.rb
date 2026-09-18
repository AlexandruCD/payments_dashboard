# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CreateTransactionService do
  let(:merchant) { build_stubbed(:merchant) }

  {
    "authorize" => Transactions::CreateAuthorizeService,
    "capture" => Transactions::CreateCaptureService,
    "refund" => Transactions::CreateRefundService,
    "void" => Transactions::CreateVoidService
  }.each do |type, service_class|
    it "delegates #{type} with the original inputs and returns its result" do
      params = { type: type, amount: 40, referenced_transaction_uuid: "reference" }
      result = ServiceResult.success(entity: Object.new)
      expect(service_class).to receive(:call).with(merchant: merchant, params: params).and_return(result)

      expect(described_class.call(merchant: merchant, params: params)).to equal(result)
    end
  end

  [ nil, "unknown", "AuthorizeTransaction" ].each do |type|
    it "rejects unsupported type #{type.inspect} without creating a transaction" do
      result = nil
      expect { result = described_class.call(merchant: merchant, params: { type: type }) }
        .not_to change(Transaction, :count)

      expect(result).to be_failure
      expect(result.entity).to be_nil
      expect(result.errors).to eq([ { attribute: :type, code: :invalid, message: "invalid transaction type" } ])
    end
  end

  it "preserves a delegated failure result" do
    params = { type: "capture" }
    result = ServiceResult.failure(entity: build_stubbed(:capture_transaction, status: "error"), errors: [])
    allow(Transactions::CreateCaptureService).to receive(:call).and_return(result)

    expect(described_class.call(merchant: merchant, params: params)).to equal(result)
  end
end
