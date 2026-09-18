# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionProcessingJob, type: :job do
  let(:authorize_transaction) { create(:authorize_transaction) }

  it "delegates to the service" do
    expect(Transactions::ProcessAuthorizationService).to receive(:call).with(authorize_transaction: authorize_transaction)

    described_class.perform_now(authorize_transaction)
  end
end
