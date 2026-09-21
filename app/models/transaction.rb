# frozen_string_literal: true

class Transaction < ApplicationRecord
  include Auditable

  belongs_to :merchant

  validates :uuid,           presence: true, uniqueness: true
  validates :customer_email, presence: true,
                             format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount,         numericality: { greater_than: 0 }, allow_nil: true

  before_validation :generate_uuid, on: :create

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
