# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaleAuthorizationSweeperJob, type: :job do
  describe "#perform" do
    it "marks a pending authorize transaction older than the threshold as error" do
      stale = create(:authorize_transaction)
      stale.update_column(:created_at, 2.hours.ago)

      described_class.perform_now

      expect(stale.reload.status).to eq("error")
    end

    it "enqueues a notification for swept transactions" do
      stale = create(:authorize_transaction)
      stale.update_column(:created_at, 2.hours.ago)

      expect { described_class.perform_now }.to have_enqueued_job(NotificationJob).with(stale)
    end

    it "leaves a recently created pending transaction alone" do
      recent = create(:authorize_transaction)

      described_class.perform_now

      expect(recent.reload.status).to eq("pending")
    end

    it "leaves an already-processed transaction alone" do
      processed = create(:authorize_transaction, status: "approved")
      processed.update_column(:created_at, 2.hours.ago)

      described_class.perform_now

      expect(processed.reload.status).to eq("approved")
    end
  end
end
