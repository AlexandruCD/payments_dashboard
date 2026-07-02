# frozen_string_literal: true

class Merchant < ApplicationRecord
  include Auditable

  # Own credentials, used for JWT auth (separate from User, which is UI-only)
  has_secure_password

  belongs_to :user

  has_many :transactions, dependent: :restrict_with_error

  STATUSES = %w[active inactive].freeze

  validates :name,     presence: true
  validates :email,    presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status,   presence: true, inclusion: { in: STATUSES }
  validates :password, length: { minimum: 8 }, allow_nil: true

  scope :active,   -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end
end
