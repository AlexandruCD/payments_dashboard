# frozen_string_literal: true

class MerchantUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string

  validates :email, :password, presence: true
  validate :merchant_is_available

  attr_reader :merchant, :merchant_user

  def initialize(merchant:, attributes: {})
    @merchant = merchant
    super(attributes)
  end

  def save
    return false if invalid?

    @merchant_user = MerchantUser.new(email: email, password: password, merchant: merchant)
    return true if merchant_user.save

    merchant_user.errors.full_messages.each { |message| errors.add(:base, message) }
    false
  rescue ActiveRecord::RecordNotUnique
    errors.add(:merchant, "already has a UI login")
    false
  end

  private

  def merchant_is_available
    if !merchant&.persisted?
      errors.add(:merchant, "must exist")
    elsif merchant.merchant_user.present?
      errors.add(:merchant, "already has a UI login")
    end
  end
end
