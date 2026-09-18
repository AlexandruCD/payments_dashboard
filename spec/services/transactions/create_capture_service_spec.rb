# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CreateCaptureService do
  let(:merchant) { create(:merchant) }
  let(:authorize_transaction) { create(:authorize_transaction, merchant: merchant, amount: 100, status: "approved") }

  def call(params)
    described_class.call(merchant: merchant, params: params)
  end

  describe "reusing an instance" do
    it "does not reuse a previous merchant, reference or failure" do
      service = described_class.new
      other_merchant = create(:merchant)
      params = { amount: 40, referenced_transaction_uuid: authorize_transaction.uuid }

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

  it "rolls back the capture and propagates unexpected parent update errors" do
    allow(AuthorizeTransaction).to receive(:find_by).and_return(authorize_transaction)
    allow(authorize_transaction).to receive(:update!).and_raise(ActiveRecord::StatementInvalid, "update failed")

    expect do
      expect { call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid) }
        .to raise_error(ActiveRecord::StatementInvalid, "update failed")
    end.not_to change(CaptureTransaction, :count)
  end

  it "returns validation errors independently of the saved entity's errors" do
    result = call(amount: 150, referenced_transaction_uuid: authorize_transaction.uuid)
    result.entity.errors.clear

    expect(result).to be_failure
    expect(result.errors).to include(
      attribute: :amount, code: :invalid, message: "Amount exceeds remaining amount of 100.0"
    )
  end

  describe ".call" do
    context "when the referenced authorize transaction is valid" do
      it "creates an approved capture transaction" do
        result = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
        expect(transaction.referenced_transaction).to eq(authorize_transaction)
      end

      it "transitions the authorize transaction to captured" do
        call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        expect(authorize_transaction.reload.status).to eq("captured")
      end

      it "allows multiple partial captures within the authorized amount" do
        call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        result = call(amount: 60, referenced_transaction_uuid: authorize_transaction.uuid)
        second = result.entity

        expect(second.status).to eq("approved")
        expect(authorize_transaction.total_captured).to eq(100)
      end

      it "inherits customer_email from the referenced authorize when not supplied" do
        result = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid)
        transaction = result.entity
        expect(transaction.customer_email).to eq(authorize_transaction.customer_email)
      end

      it "ignores a client-supplied status" do
        result = call(amount: 40, referenced_transaction_uuid: authorize_transaction.uuid, status: "error")
        transaction = result.entity
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("approved")
      end
    end

    context "when the capture would exceed the authorized amount" do
      it "persists the transaction with status error and leaves the authorize transaction alone" do
        result = call(amount: 150, referenced_transaction_uuid: authorize_transaction.uuid)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
        expect(authorize_transaction.reload.status).to eq("approved")
      end
    end

    context "when the referenced transaction does not exist" do
      it "persists the transaction with status error" do
        result = call(amount: 40, referenced_transaction_uuid: "missing-uuid")
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

        result = call(amount: 40, referenced_transaction_uuid: other_authorize.uuid)
        transaction = result.entity

        expect(result).to be_failure
        expect(result.errors).not_to be_empty
        expect(transaction.status).to eq("error")
        expect(other_authorize.reload.status).to eq("approved")
      end
    end
  end
end
