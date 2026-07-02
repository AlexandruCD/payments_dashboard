# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::AuthorizeService do
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
        transaction = described_class.call(merchant: merchant, params: params)

        expect(transaction).to be_persisted
        expect(transaction).to be_a(AuthorizeTransaction)
        expect(transaction.status).to eq("pending")
        expect(transaction.merchant).to eq(merchant)
      end

      it "ignores a client-supplied status" do
        transaction = described_class.call(merchant: merchant, params: params.merge(status: "approved"))
        expect(transaction.status).to eq("pending")
      end

      it "enqueues a job to process the transaction" do
        expect { described_class.call(merchant: merchant, params: params) }
          .to have_enqueued_job(TransactionProcessingJob)
      end
    end

    context "with invalid params" do
      let(:params) { { amount: nil, customer_email: "customer@example.com", notification_url: nil } }

      it "does not persist the transaction" do
        transaction = described_class.call(merchant: merchant, params: params)

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
