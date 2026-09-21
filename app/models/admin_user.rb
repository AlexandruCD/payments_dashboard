# frozen_string_literal: true

class AdminUser < User
  def admin?
    true
  end
end
