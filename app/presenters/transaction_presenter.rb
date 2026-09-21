# frozen_string_literal: true

class TransactionPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper

  STATUS_BADGE_CLASSES = {
    "pending" => "bg-secondary",
    "approved" => "bg-success",
    "captured" => "bg-info",
    "refunded" => "bg-warning",
    "voided" => "bg-dark",
    "error" => "bg-danger"
  }.freeze

  # to_param delegated so path helpers (e.g. transaction_path(presenter)) resolve to
  # the real record's id instead of falling back to Object#to_param (its inspect string).
  delegate :id, :uuid, :status, :customer_email, :customer_phone, :created_at, :merchant, :to_param,
           to: :transaction

  def type_label
    transaction.type.sub("Transaction", "")
  end

  def formatted_amount
    transaction.amount.nil? ? "—" : number_to_currency(transaction.amount)
  end

  def status_badge_class
    STATUS_BADGE_CLASSES.fetch(status, "bg-secondary")
  end

  def referenced_uuid
    return unless transaction.respond_to?(:referenced_transaction)

    transaction.referenced_transaction&.uuid
  end

  private

  alias_method :transaction, :entity
end
