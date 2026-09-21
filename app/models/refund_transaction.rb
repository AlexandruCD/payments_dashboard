# frozen_string_literal: true

class RefundTransaction < Transaction
  include AASM
  include ReferenceableTransaction

  belongs_to :capture_transaction,
             class_name:  "CaptureTransaction",
             foreign_key: :referenced_transaction_id

  validates :amount, presence: true

  validates_referenced_status in: %w[approved refunded]
  validates_amount_within_remaining

  aasm column: :status do
    state :approved, initial: true
    state :error

    event :mark_failed do
      transitions from: :approved, to: :error
    end
  end
end
