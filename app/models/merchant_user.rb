# frozen_string_literal: true

class MerchantUser < User
  has_one :merchant, foreign_key: :user_id, inverse_of: :merchant_user

  def merchant?
    true
  end
end
