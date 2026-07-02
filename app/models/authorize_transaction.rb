# frozen_string_literal: true

class AuthorizeTransaction < Transaction
  has_many :capture_transactions,
           class_name:  "CaptureTransaction",
           foreign_key: :referenced_transaction_id
  has_many :void_transactions,
           class_name:  "VoidTransaction",
           foreign_key: :referenced_transaction_id

  validates :amount,           presence: true
  validates :notification_url, presence: true, url: true

  before_validation :set_default_status, on: :create

  def total_captured
    capture_transactions.where(status: "approved").sum(:amount)
  end

  def fully_captured?
    total_captured >= amount
  end

  def remaining_amount
    amount - total_captured
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
end
