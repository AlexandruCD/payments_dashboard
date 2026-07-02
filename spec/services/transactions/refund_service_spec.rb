# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::RefundService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }
  let(:capture_transaction) do
    create(:capture_transaction, merchant: merchant, referenced_transaction: authorize_transaction,
                                  amount: 100, status: "approved")
  end

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe ".call" do
    context "when the referenced capture transaction is valid" do
      it "creates an approved refund transaction" do
        transaction = call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("approved")
        expect(transaction.referenced_transaction).to eq(capture_transaction)
      end

      it "transitions the capture transaction to refunded" do
        call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)
        expect(capture_transaction.reload.status).to eq("refunded")
      end

      it "allows multiple partial refunds within the captured amount" do
        call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid)
        second = call(amount: 60, referenced_transaction_uuid: capture_transaction.uuid)

        expect(second.status).to eq("approved")
        expect(capture_transaction.total_refunded).to eq(100)
      end

      it "ignores a client-supplied status" do
        transaction = call(amount: 40, referenced_transaction_uuid: capture_transaction.uuid, status: "error")
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the refund would exceed the captured amount" do
      it "persists the transaction with status error and leaves the capture transaction alone" do
        transaction = call(amount: 150, referenced_transaction_uuid: capture_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("error")
        expect(capture_transaction.reload.status).to eq("approved")
      end
    end

    context "when the referenced capture transaction belongs to another merchant" do
      it "persists the transaction with status error" do
        other_authorize = create(:authorize_transaction, amount: 100, status: "approved")
        other_capture = create(:capture_transaction, referenced_transaction: other_authorize,
                                                       amount: 100, status: "approved")

        transaction = call(amount: 40, referenced_transaction_uuid: other_capture.uuid)

        expect(transaction.status).to eq("error")
        expect(other_capture.reload.status).to eq("approved")
      end
    end
  end
end
