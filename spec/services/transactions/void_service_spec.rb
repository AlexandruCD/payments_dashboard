# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::VoidService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe ".call" do
    context "when the referenced authorize transaction is approved" do
      it "creates an approved void transaction without an amount" do
        transaction = call(referenced_transaction_uuid: authorize_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("approved")
        expect(transaction.amount).to be_nil
      end

      it "transitions the authorize transaction to voided" do
        call(referenced_transaction_uuid: authorize_transaction.uuid)
        expect(authorize_transaction.reload.status).to eq("voided")
      end

      it "ignores a client-supplied status" do
        transaction = call(referenced_transaction_uuid: authorize_transaction.uuid, status: "error")
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the referenced authorize transaction is not approved" do
      it "persists the transaction with status error" do
        authorize_transaction.update!(status: "captured")
        transaction = call(referenced_transaction_uuid: authorize_transaction.uuid)

        expect(transaction).to be_persisted
        expect(transaction.status).to eq("error")
      end
    end

    context "when the referenced authorize transaction belongs to another merchant" do
      it "persists the transaction with status error and leaves the other merchant's transaction alone" do
        other_authorize = create(:authorize_transaction, amount: 100, status: "approved")

        transaction = call(referenced_transaction_uuid: other_authorize.uuid)

        expect(transaction.status).to eq("error")
        expect(other_authorize.reload.status).to eq("approved")
      end
    end
  end
end
