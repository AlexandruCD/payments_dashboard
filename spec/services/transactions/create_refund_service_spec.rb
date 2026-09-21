# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CreateRefundService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }
  let(:capture_transaction) do
    create(:capture_transaction, merchant: merchant, referenced_transaction: authorize_transaction,
                                  amount: 100, status: "approved")
  end

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe "reusing an instance" do
    it "does not reuse a previous merchant, reference or failure" do
      service = described_class.new
      other_merchant = create(:merchant)
      params = { amount: 40, referenced_transaction_uuid: capture_transaction.uuid }

      rejected = service.call(merchant: other_merchant, params: params)
      accepted = service.call(merchant: merchant, params: params)

      expect(rejected).to be_failure
      expect(rejected.entity).to be_persisted
      expect(rejected.entity.merchant).to eq(other_merchant)
      expect(rejected.entity.referenced_transaction).to be_nil
      expect(accepted).to be_success
      expect(accepted.errors).to be_empty
      expect(accepted.entity.merchant).to eq(merchant)
      expect(accepted.entity.referenced_transaction).to eq(capture_transaction)
      expect(rejected.errors).not_to be_empty
    end
  end

  describe ".call" do
    context "when the referenced capture transaction is valid" do
      it "creates an approved refund transaction" do
        result = call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
        expect(transaction.referenced_transaction).to eq(capture_transaction)
      end

      it "transitions the capture transaction to refunded" do
        call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)
        expect(capture_transaction.reload.status).to eq("refunded")
      end

      it "allows multiple partial refunds within the captured amount" do
        call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)
        audit_count = capture_transaction.audit_logs.count
        result = call(amount: 60, referenced_transaction_uuid: capture_transaction.uuid)
        second = result.entity

        expect(second.status).to eq("approved")
        expect(capture_transaction.total_refunded).to eq(100)
        expect(capture_transaction.audit_logs.count).to eq(audit_count)
      end

      it "ignores a client-supplied status" do
        result = call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid, status: "error")
        transaction = result.entity
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the refund would exceed the captured amount" do
      it "persists the transaction with status error and leaves the capture transaction alone" do
        result = call(amount: 150, referenced_transaction_uuid: capture_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
        expect(capture_transaction.reload.status).to eq("approved")
      end
    end

    context "when the referenced capture transaction belongs to another merchant" do
      it "persists the transaction with status error" do
        other_authorize = create(:authorize_transaction, amount: 100, status: "approved")
        other_capture = create(:capture_transaction, referenced_transaction: other_authorize,
                                                       amount: 100, status: "approved")

        result = call(amount: 40, referenced_transaction_uuid: other_capture.uuid)
        transaction = result.entity

        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
        expect(other_capture.reload.status).to eq("approved")
      end
    end
  end
end
