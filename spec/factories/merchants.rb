# frozen_string_literal: true

FactoryBot.define do
  factory :merchant do
    name        { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    email       { Faker::Internet.unique.email }
    status      { 'active' }
    association :user
  end
end
