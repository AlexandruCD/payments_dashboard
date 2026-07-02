# frozen_string_literal: true

FactoryBot.define do
  factory :audit_log do
    association :auditable, factory: :merchant
    action { "status_changed" }
    details { "active -> inactive" }
  end
end
