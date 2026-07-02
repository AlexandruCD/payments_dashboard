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
  attribute :password, :string
  attribute :user_email, :string
  attribute :user_password, :string

  validates :name, :email, :password, :user_email, :user_password, presence: true

  attr_reader :merchant

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      user = User.create!(email: user_email, password: user_password, role: "merchant")
      @merchant = Merchant.create!(
        name: name, description: description, email: email,
        status: status, password: password, user: user
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.full_messages.each { |message| errors.add(:base, message) }
    false
  end
end
