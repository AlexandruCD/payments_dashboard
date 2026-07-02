# frozen_string_literal: true

class MerchantPresenter
  # to_param delegated so path helpers (e.g. admin_merchant_path(presenter)) resolve
  # to the real record's id instead of falling back to Object#to_param (its inspect string).
  delegate :id, :name, :description, :email, :status, :transactions, :to_param, to: :merchant

  def initialize(merchant)
    @merchant = merchant
  end

  def status_badge_class
    merchant.active? ? "bg-success" : "bg-secondary"
  end

  def transaction_count
    transactions.count
  end

  private

  attr_reader :merchant
end
