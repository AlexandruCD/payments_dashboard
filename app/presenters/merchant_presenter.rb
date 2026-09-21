# frozen_string_literal: true

class MerchantPresenter < ApplicationPresenter
  # to_param delegated so path helpers (e.g. admin_merchant_path(presenter)) resolve
  # to the real record's id instead of falling back to Object#to_param (its inspect string).
  delegate :id, :name, :description, :email, :status, :transactions, :to_param, to: :merchant

  def status_badge_class
    merchant.active? ? "bg-success" : "bg-secondary"
  end

  def status_label
    I18n.t(status, scope: :merchant_statuses)
  end

  def transaction_count
    transactions.count
  end

  private

  alias_method :merchant, :entity
end
