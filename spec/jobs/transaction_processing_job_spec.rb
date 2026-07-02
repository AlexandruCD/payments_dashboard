# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionProcessingJob, type: :job do
  let(:authorize_transaction) { create(:authorize_transaction) }

  describe "#perform" do
    it "transitions to approved when that's the random outcome" do
      allow(described_class::OUTCOMES).to receive(:sample).and_return("approved")

      described_class.perform_now(authorize_transaction)

      expect(authorize_transaction.reload.status).to eq("approved")
    end

    it "transitions to error when that's the random outcome" do
      allow(described_class::OUTCOMES).to receive(:sample).and_return("error")

      described_class.perform_now(authorize_transaction)

      expect(authorize_transaction.reload.status).to eq("error")
    end

    it "enqueues a notification job once processed" do
      expect { described_class.perform_now(authorize_transaction) }
        .to have_enqueued_job(NotificationJob).with(authorize_transaction)
    end

    it "does nothing when the transaction is not pending" do
      authorize_transaction.update!(status: "approved")

      expect { described_class.perform_now(authorize_transaction) }
        .not_to have_enqueued_job(NotificationJob)
      expect(authorize_transaction.reload.status).to eq("approved")
    end
  end
end
