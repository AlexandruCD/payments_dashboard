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
        ServiceResult.success(entity: transaction)
      else
        result = validation_failure(transaction)
        transaction.mark_failed
        transaction.save!(validate: false)
        result
      end
    end
  end
end
