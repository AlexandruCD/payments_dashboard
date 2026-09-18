# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CreateVoidService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe "reusing an instance" do
    it "does not reuse a previous merchant, reference or failure" do
      service = described_class.new
      other_merchant = create(:merchant)
      params = { referenced_transaction_uuid: authorize_transaction.uuid }

      rejected = service.call(merchant: other_merchant, params: params)
      accepted = service.call(merchant: merchant, params: params)

      expect(rejected).to be_failure
      expect(rejected.entity).to be_persisted
      expect(rejected.entity.merchant).to eq(other_merchant)
      expect(rejected.entity.referenced_transaction).to be_nil
      expect(accepted).to be_success
      expect(accepted.errors).to be_empty
      expect(accepted.entity.merchant).to eq(merchant)
      expect(accepted.entity.referenced_transaction).to eq(authorize_transaction)
      expect(rejected.errors).not_to be_empty
    end
  end

  describe ".call" do
    context "when the referenced authorize transaction is approved" do
      it "creates an approved void transaction without an amount" do
        result = call(referenced_transaction_uuid: authorize_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
        expect(transaction.amount).to be_nil
      end

      it "transitions the authorize transaction to voided" do
        call(referenced_transaction_uuid: authorize_transaction.uuid)
        expect(authorize_transaction.reload.status).to eq("voided")
      end

      it "ignores a client-supplied status" do
        result = call(referenced_transaction_uuid: authorize_transaction.uuid, status: "error")
        transaction = result.entity
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the referenced authorize transaction is not approved" do
      it "persists the transaction with status error" do
        authorize_transaction.update!(status: "captured")
        result = call(referenced_transaction_uuid: authorize_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
      end
    end

    context "when the referenced authorize transaction belongs to another merchant" do
      it "persists the transaction with status error and leaves the other merchant's transaction alone" do
        other_authorize = create(:authorize_transaction, amount: 100, status: "approved")

        result = call(referenced_transaction_uuid: other_authorize.uuid)
        transaction = result.entity

        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
        expect(other_authorize.reload.status).to eq("approved")
      end
    end
  end
end
