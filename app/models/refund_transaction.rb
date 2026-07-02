# frozen_string_literal: true

class RefundTransaction < Transaction
  include ReferenceableTransaction

  belongs_to :capture_transaction,
             class_name:  "CaptureTransaction",
             foreign_key: :referenced_transaction_id

  validates :amount, presence: true

  validates_referenced_status in: %w[approved refunded]
  validates_amount_within_remaining
end
