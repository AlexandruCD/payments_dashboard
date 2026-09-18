# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationJob, type: :job do
  let(:authorize_transaction) { create(:authorize_transaction, status: "approved") }

  it "delegates to the notification service" do
    expect(Notifications::SendTransactionNotificationService).to receive(:call)
      .with(authorize_transaction: authorize_transaction)

    described_class.perform_now(authorize_transaction)
  end

  [ Net::OpenTimeout, Net::ReadTimeout, SocketError ].each do |error_class|
    it "retries #{error_class} on the default queue with a delay" do
      allow(Net::HTTP).to receive(:post_form).and_raise(error_class)

      expect { described_class.perform_now(authorize_transaction) }
        .to have_enqueued_job(described_class).with(authorize_transaction).on_queue("default").at(a_value > Time.current)
    end
  end

  it "raises after the fifth failed attempt without enqueueing another retry" do
    allow(Net::HTTP).to receive(:post_form).and_raise(Net::ReadTimeout)
    job = described_class.new(authorize_transaction)
    4.times { job.perform_now }
    clear_enqueued_jobs

    expect do
      expect { job.perform_now }.to raise_error(Net::ReadTimeout)
    end.not_to have_enqueued_job(described_class)
  end

  it "does not retry unrelated exceptions" do
    allow(Net::HTTP).to receive(:post_form).and_raise(ArgumentError, "invalid request")

    expect do
      expect { described_class.perform_now(authorize_transaction) }.to raise_error(ArgumentError, "invalid request")
    end.not_to have_enqueued_job(described_class)
  end
end
