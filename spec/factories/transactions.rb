# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    association :merchant
    sequence(:customer_email) { |n| "customer#{n}@example.com" }
    customer_phone { Faker::PhoneNumber.cell_phone_in_e164 }

    factory :authorize_transaction, class: 'AuthorizeTransaction' do
      amount { 100.0 }
      notification_url { 'https://merchant.example.com/webhooks/notifications' }
    end

    factory :capture_transaction, class: 'CaptureTransaction' do
      amount { 50.0 }
      status { 'approved' }
      referenced_transaction { association :authorize_transaction, merchant: merchant, status: 'approved' }
    end

    factory :refund_transaction, class: 'RefundTransaction' do
      amount { 25.0 }
      status { 'approved' }
      referenced_transaction { association :capture_transaction, merchant: merchant, status: 'approved' }
    end

    factory :void_transaction, class: 'VoidTransaction' do
      status { 'approved' }
      referenced_transaction { association :authorize_transaction, merchant: merchant, status: 'approved' }
    end
  end
end
