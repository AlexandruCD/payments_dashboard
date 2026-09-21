# frozen_string_literal: true

# Admin-facing form object: creating a Merchant also means creating the User
# login it needs to access the UI, so both are built together, atomically.
class MerchantRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :description, :string
  attribute :email, :string
  attribute :status, :string, default: "active"
  attribute :user_email, :string
  attribute :user_password, :string

  validates :name, :email, :user_email, :user_password, presence: true

  attr_reader :merchant

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      merchant_user = MerchantUser.create!(email: user_email, password: user_password)
      @merchant = Merchant.create!(
        name: name, description: description, email: email,
        status: status, merchant_user: merchant_user
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.full_messages.each { |message| errors.add(:base, message) }
    false
  end
end
