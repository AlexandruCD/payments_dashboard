# frozen_string_literal: true

class Transaction < ApplicationRecord
  include Auditable

  belongs_to :merchant
  belongs_to :referenced_transaction, class_name: "Transaction", optional: true

  STATUSES = %w[pending approved captured voided refunded error].freeze

  validates :uuid,           presence: true, uniqueness: true
  validates :customer_email, presence: true,
                             format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status,         presence: true, inclusion: { in: STATUSES }
  validates :amount,         numericality: { greater_than: 0 }, allow_nil: true

  scope :approved,  -> { where(status: "approved") }
  scope :captured,  -> { where(status: "captured") }
  scope :voided,    -> { where(status: "voided") }
  scope :refunded,  -> { where(status: "refunded") }
  scope :error,     -> { where(status: "error") }

  before_validation :generate_uuid, on: :create

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
