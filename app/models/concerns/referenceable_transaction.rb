# frozen_string_literal: true

module ReferenceableTransaction
  extend ActiveSupport::Concern

  included do
    belongs_to :referenced_transaction, class_name: "Transaction", optional: true
  end

  class_methods do
    # on: :create only, so later status changes (e.g. capture -> refunded) don't re-trigger these
    def validates_referenced_status(in:)
      allowed_statuses = binding.local_variable_get(:in)
      define_method(:allowed_referenced_statuses) { allowed_statuses }
      validate :referenced_transaction_status_allowed, on: :create
    end

    def validates_amount_within_remaining
      validate :amount_within_referenced_remaining, on: :create
    end
  end

  private

  def referenced_transaction_status_allowed
    return unless referenced_transaction
    return if allowed_referenced_statuses.include?(referenced_transaction.status)

    errors.add(:referenced_transaction, "must be #{allowed_referenced_statuses.join(' or ')}")
  end

  def amount_within_referenced_remaining
    return unless referenced_transaction && amount

    remaining = referenced_transaction.remaining_amount
    return if amount <= remaining

    errors.add(:amount, "exceeds remaining amount of #{remaining}")
  end
end
