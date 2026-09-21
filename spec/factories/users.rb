# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }

    factory :admin_user, class: 'AdminUser' do
    end

    factory :merchant_user, class: 'MerchantUser' do
    end
  end
end
