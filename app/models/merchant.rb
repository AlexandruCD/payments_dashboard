# frozen_string_literal: true

class Merchant < ApplicationRecord
  include AASM
  include Auditable

  has_many :transactions, dependent: :restrict_with_error
  has_one :merchant_user, inverse_of: :merchant, dependent: :destroy

  STATUSES = %w[active inactive].freeze

  validates :name,     presence: true
  validates :email,    presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: URI::MailTo::EMAIL_REGEXP }
  aasm column: :status do
    state :active, initial: true
    state :inactive

    event :activate do
      transitions from: :inactive, to: :active
    end

    event :deactivate do
      transitions from: :active, to: :inactive
    end
  end
end
