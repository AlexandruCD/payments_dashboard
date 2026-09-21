# frozen_string_literal: true

class MerchantForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :description, :string
  attribute :email, :string
  attribute :status, :string, default: "active"

  attr_reader :merchant

  def save
    @merchant = Merchant.new(attributes)
    return true if merchant.save

    merchant.errors.full_messages.each { |message| errors.add(:base, message) }
    false
  end
end
