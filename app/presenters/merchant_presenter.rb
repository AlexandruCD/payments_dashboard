# frozen_string_literal: true

class MerchantPresenter
  delegate :id, :name, :description, :email, :status, :transactions, to: :merchant

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
