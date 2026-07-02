# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CaptureService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe ".call" do
    context "when the referenced authorize transaction is valid" do
      it "creates an approved capture transaction" do
        transaction = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("approved")
        expect(transaction.referenced_transaction).to eq(authorize_transaction)
      end

      it "transitions the authorize transaction to captured" do
        call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        expect(authorize_transaction.reload.status).to eq("captured")
      end

      it "allows multiple partial captures within the authorized amount" do
        call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        second = call(amount: 60, referenced_transaction_uuid: authorize_transaction.uuid)

        expect(second.status).to eq("approved")
        expect(authorize_transaction.total_captured).to eq(100)
      end

      it "inherits customer_email from the referenced authorize when not supplied" do
        transaction = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        expect(transaction.customer_email).to eq(authorize_transaction.customer_email)
      end

      it "ignores a client-supplied status" do
        transaction = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid, status: "error")
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the capture would exceed the authorized amount" do
      it "persists the transaction with status error and leaves the authorize transaction alone" do
        transaction = call(amount: 150, referenced_transaction_uuid: authorize_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("error")
        expect(authorize_transaction.reload.status).to eq("approved")
      end
    end

    context "when the referenced transaction does not exist" do
      it "persists the transaction with status error" do
        transaction = call(amount: 40, referenced_transaction_uuid: "missing-uuid")

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("error")
      end
    end

    context "when the referenced authorize transaction belongs to another merchant" do
      it "persists the transaction with status error and leaves the other merchant's transaction alone" do
        other_authorize = create(:authorize_transaction, amount: 100, status: "approved")

        transaction = call(amount: 40, referenced_transaction_uuid: other_authorize.uuid)

        expect(transaction.status).to eq("error")
        expect(other_authorize.reload.status).to eq("approved")
      end
    end
  end
end
