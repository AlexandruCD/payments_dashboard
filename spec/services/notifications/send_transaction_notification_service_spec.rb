# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::SendTransactionNotificationService do
  let(:authorize_transaction) do
    build_stubbed(:authorize_transaction, uuid: "transaction-uuid", amount: 100, status: "approved",
                                        notification_url: "https://merchant.example.com/notify")
  end

  it "posts form-urlencoded transaction fields and returns the HTTP response" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    expect(Net::HTTP).to receive(:post_form).with(
      URI("https://merchant.example.com/notify"),
      "unique_id" => "transaction-uuid", "amount" => "100.0", "status" => "approved"
    ).and_return(response)

    result = described_class.call(authorize_transaction: authorize_transaction)

    expect(result).to be_success
    expect(result.entity).to equal(response)
  end

  it "preserves the existing handling of non-success HTTP responses" do
    response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
    allow(Net::HTTP).to receive(:post_form).and_return(response)

    result = described_class.call(authorize_transaction: authorize_transaction)

    expect(result).to be_success
    expect(result.entity).to equal(response)
  end

  [ Net::OpenTimeout, Net::ReadTimeout, SocketError ].each do |error_class|
    it "propagates #{error_class} so the job can retry" do
      allow(Net::HTTP).to receive(:post_form).and_raise(error_class)

      expect { described_class.call(authorize_transaction: authorize_transaction) }.to raise_error(error_class)
    end
  end
end
