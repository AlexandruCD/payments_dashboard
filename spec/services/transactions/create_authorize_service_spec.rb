# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::CreateAuthorizeService do
  let(:merchant) { create(:merchant) }

  describe ".call" do
    context "with valid params" do
      let(:params) do
        {
          amount: 100,
          customer_email: "customer@example.com",
          customer_phone: "+15555550100",
          notification_url: "https://merchant.example.com/notify"
        }
      end

      it "persists an AuthorizeTransaction with status pending" do
        result = described_class.call(merchant: merchant, params: params)
        transaction = result.entity

        expect(transaction).to be_persisted
        expect(transaction).to be_a(AuthorizeTransaction)
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("pending")
        expect(transaction.merchant).to eq(merchant)
      end

      it "ignores a client-supplied status" do
        result = described_class.call(merchant: merchant, params: params.merge(status: "approved"))
        transaction = result.entity
        expect(result).to be_success
        expect(result.errors).to be_empty
        expect(transaction.status).to eq("pending")
      end

      it "does not retain inputs or errors when reusing an instance" do
        service = described_class.new
        other_merchant = create(:merchant)
        rejected = service.call(merchant: merchant, params: params.merge(amount: nil))
        accepted = service.call(merchant: other_merchant, params: params.merge(amount: 25))

        expect(rejected).to be_failure
        expect(rejected.entity).not_to be_persisted
        expect(rejected.entity.merchant).to eq(merchant)
        expect(accepted).to be_success
        expect(accepted.errors).to be_empty
        expect(accepted.entity.merchant).to eq(other_merchant)
        expect(accepted.entity.amount).to eq(25)
        expect(rejected.errors).not_to be_empty
      end

      it "propagates unexpected enqueue errors" do
        allow(TransactionProcessingJob).to receive(:perform_later).and_raise(RuntimeError, "queue unavailable")

        expect { described_class.call(merchant: merchant, params: params) }
          .to raise_error(RuntimeError, "queue unavailable")
      end

      it "enqueues a job to process the transaction" do
        expect { described_class.call(merchant: merchant, params: params) }
          .to have_enqueued_job(TransactionProcessingJob)
      end
    end

    context "with invalid params" do
      let(:params) { { amount: nil, customer_email: "customer@example.com", notification_url: nil } }

      it "does not persist the transaction" do
        result = described_class.call(merchant: merchant, params: params)
        transaction = result.entity

        expect(result).to be_failure
        expect(result.errors).to include(attribute: :amount, code: :blank, message: "Amount can't be blank")
        expect(transaction).not_to be_persisted
        expect(transaction.errors).not_to be_empty
      end

      it "does not enqueue a processing job" do
        expect { described_class.call(merchant: merchant, params: params) }
          .not_to have_enqueued_job(TransactionProcessingJob)
      end
    end
  end
end
