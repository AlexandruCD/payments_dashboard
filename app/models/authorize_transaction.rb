# frozen_string_literal: true

class AuthorizeTransaction < Transaction
  include AASM

  has_many :capture_transactions,
           class_name:  "CaptureTransaction",
           foreign_key: :referenced_transaction_id
  has_many :void_transactions,
           class_name:  "VoidTransaction",
           foreign_key: :referenced_transaction_id

  validates :amount,           presence: true
  validates :notification_url, presence: true, url: true

  aasm column: :status do
    state :pending, initial: true
    state :approved, :captured, :voided, :error

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :mark_failed do
      transitions from: :pending, to: :error
    end

    event :capture do
      transitions from: %i[approved captured], to: :captured
    end

    event :void do
      transitions from: :approved, to: :voided
    end
  end

  def total_captured
    capture_transactions.approved.sum(:amount)
  end

  def fully_captured?
    total_captured >= amount
  end

  def remaining_amount
    amount - total_captured
  end
end
