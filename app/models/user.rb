# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  ROLES = %w[admin merchant].freeze

  has_one :merchant

  validates :role, inclusion: { in: ROLES }

  scope :admins,    -> { where(role: "admin") }
  scope :merchants, -> { where(role: "merchant") }

  def admin?
    role == "admin"
  end

  def merchant?
    role == "merchant"
  end
end
