# frozen_string_literal: true

class Merchant < ApplicationRecord
  include Auditable

  belongs_to :merchant_user, class_name: "MerchantUser", foreign_key: :user_id, inverse_of: :merchant

  has_many :transactions, dependent: :restrict_with_error

  STATUSES = %w[active inactive].freeze

  validates :name,     presence: true
  validates :email,    presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status,   presence: true, inclusion: { in: STATUSES }

  scope :active,   -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }

  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end
end
