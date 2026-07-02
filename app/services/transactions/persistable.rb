# frozen_string_literal: true

module Transactions
  module Persistable
    private

    # Capture/Refund/Void: an invalid submission is still persisted, with status
    # "error", per spec. Authorize doesn't use this — it behaves like a normal
    # failed create, since nothing references it yet.
    def persist_or_error(transaction)
      if transaction.valid?
        transaction.save!
      else
        transaction.status = "error"
        transaction.save!(validate: false)
      end
      transaction
    end
  end
end
