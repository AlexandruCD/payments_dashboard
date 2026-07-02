# frozen_string_literal: true

class CaptureTransaction < Transaction
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

  def total_refunded
    refund_transactions.where(status: "approved").sum(:amount)
  end

  def remaining_amount
    amount - total_refunded
  end
end
