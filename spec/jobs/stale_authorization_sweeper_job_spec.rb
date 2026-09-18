# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaleAuthorizationSweeperJob, type: :job do
  it "delegates to the service" do
    expect(Transactions::SweepStaleAuthorizationsService).to receive(:call).with(no_args)

    described_class.perform_now
  end
end
