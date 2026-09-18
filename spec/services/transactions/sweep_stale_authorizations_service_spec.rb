# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::SweepStaleAuthorizationsService do
  include ActiveSupport::Testing::TimeHelpers

  describe ".call" do
    it "includes the one-hour boundary and leaves newer pending authorizations untouched" do
      travel_to(Time.current.change(usec: 0)) do
        boundary = create(:authorize_transaction, created_at: 1.hour.ago)
        newer = create(:authorize_transaction, created_at: 1.hour.ago + 1.second)

        result = described_class.call

        expect(result).to be_success
        expect(boundary.reload.status).to eq("error")
        expect(newer.reload.status).to eq("pending")
        expect(boundary.audit_logs.last.details).to eq("pending -> error")
      end
    end

    it "marks a pending authorize transaction older than the threshold as error" do
      stale = create(:authorize_transaction)
      stale.update_column(:created_at, 2.hours.ago)

      described_class.call

      expect(stale.reload.status).to eq("error")
    end

    it "enqueues a notification for swept transactions" do
      stale = create(:authorize_transaction)
      stale.update_column(:created_at, 2.hours.ago)

      expect { described_class.call }.to have_enqueued_job(NotificationJob).with(stale)
    end

    it "leaves a recently created pending transaction alone" do
      recent = create(:authorize_transaction)

      described_class.call

      expect(recent.reload.status).to eq("pending")
    end

    it "leaves an already-processed transaction alone" do
      processed = create(:authorize_transaction, status: "approved")
      processed.update_column(:created_at, 2.hours.ago)

      described_class.call

      expect(processed.reload.status).to eq("approved")
    end
  end
end
