# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationJob, type: :job do
  let(:authorize_transaction) do
    create(:authorize_transaction, amount: 100, status: "approved",
                                    notification_url: "https://merchant.example.com/notify")
  end

  describe "#perform" do
    it "posts the transaction as form-urlencoded data to the notification_url" do
      expect(Net::HTTP).to receive(:post_form) do |uri, params|
        expect(uri.to_s).to eq(authorize_transaction.notification_url)
        expect(params).to eq(
          "unique_id" => authorize_transaction.uuid,
          "amount" => authorize_transaction.amount.to_s,
          "status" => authorize_transaction.status
        )
      end

      described_class.perform_now(authorize_transaction)
    end
  end
end
