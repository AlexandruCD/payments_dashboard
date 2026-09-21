# frozen_string_literal: true

class CaptureTransaction < Transaction
  include AASM
  include ReferenceableTransaction

  belongs_to :authorize_transaction,
             class_name:  "AuthorizeTransaction",
             foreign_key: :referenced_transaction_id

  has_many :refund_transactions,
           class_name:  "RefundTransaction",
           foreign_key: :referenced_transaction_id

  validates :amount, presence: true

  validates_referenced_status in: %w[approved captured]
  validates_amount_within_remaining

  aasm column: :status do
    state :approved, initial: true
    state :refunded, :error

    event :refund do
      transitions from: %i[approved refunded], to: :refunded
    end

    event :mark_failed do
      transitions from: :approved, to: :error
    end
  end

  def total_refunded
    refund_transactions.approved.sum(:amount)
  end

  def remaining_amount
    amount - total_refunded
  end
end
