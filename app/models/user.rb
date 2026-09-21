# frozen_string_literal: true

class User < ApplicationRecord
  # No :registerable — users are only ever created via seeds or the admin
  # merchant form, never self-signup.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  TYPES = %w[AdminUser MerchantUser].freeze

  validates :type, presence: true, inclusion: { in: TYPES }

  def admin?
    false
  end

  def merchant?
    false
  end
end
