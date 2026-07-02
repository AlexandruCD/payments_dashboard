# frozen_string_literal: true

class VoidTransaction < Transaction
  include ReferenceableTransaction

  belongs_to :authorize_transaction,
             class_name:  "AuthorizeTransaction",
             foreign_key: :referenced_transaction_id

  validates_referenced_status in: %w[approved]
end
