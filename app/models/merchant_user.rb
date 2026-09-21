# frozen_string_literal: true

class MerchantUser < User
  belongs_to :merchant, inverse_of: :merchant_user

  validates :merchant_id, uniqueness: true

  def merchant?
    true
  end
end
