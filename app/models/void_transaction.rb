# frozen_string_literal: true

class VoidTransaction < Transaction
  include AASM
  include ReferenceableTransaction

  belongs_to :authorize_transaction,
             class_name:  "AuthorizeTransaction",
             foreign_key: :referenced_transaction_id

  validates_referenced_status in: %w[approved]

  aasm column: :status do
    state :approved, initial: true
    state :error

    event :mark_failed do
      transitions from: :approved, to: :error
    end
  end
end
