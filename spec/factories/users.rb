# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    role { 'merchant' }

    trait :merchant_user do
      role { 'merchant' }
    end

    trait :admin do
      role { 'admin' }
    end
  end
end
