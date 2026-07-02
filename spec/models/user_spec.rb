# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe 'associations' do
    it { is_expected.to have_one(:merchant) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }

    # Devise validations
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe 'scopes' do
    before do
      create(:user, role: 'admin')
      create(:user, :merchant_user)
    end

    it '.admins returns only admin users' do
      expect(User.admins.map(&:role)).to all(eq('admin'))
    end

    it '.merchants returns only merchant users' do
      expect(User.merchants.map(&:role)).to all(eq('merchant'))
    end
  end

  describe 'predicate methods' do
    it '#admin? returns true for admin role' do
      user.role = 'admin'
      expect(user.admin?).to be true
    end

    it '#admin? returns false for merchant role' do
      user.role = 'merchant'
      expect(user.admin?).to be false
    end

    it '#merchant? returns true for merchant role' do
      user.role = 'merchant'
      expect(user.merchant?).to be true
    end

    it '#merchant? returns false for admin role' do
      user.role = 'admin'
      expect(user.merchant?).to be false
    end
  end

  describe 'default role' do
    it 'defaults to merchant role' do
      user = User.new(email: 'test@example.com', password: 'password123')
      expect(user.role).to eq('merchant')
    end
  end
end
