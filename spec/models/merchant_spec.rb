# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Merchant, type: :model do
  subject(:merchant) { build(:merchant) }

  describe 'associations' do
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Merchant::STATUSES) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it 'is invalid with a malformed email' do
      merchant.email = 'not-an-email'
      expect(merchant).not_to be_valid
      expect(merchant.errors[:email]).to be_present
    end

    it 'is valid with a proper email' do
      merchant.email = 'merchant@example.com'
      expect(merchant).to be_valid
    end

    it 'requires a password on create' do
      merchant.password = nil
      expect(merchant).not_to be_valid
      expect(merchant.errors[:password]).to be_present
    end

    it 'rejects a password shorter than 8 characters' do
      merchant.password = 'short'
      expect(merchant).not_to be_valid
      expect(merchant.errors[:password]).to be_present
    end

    it 'authenticates with the correct password' do
      merchant.password = 'password123'
      merchant.save!
      expect(merchant.authenticate('password123')).to eq(merchant)
      expect(merchant.authenticate('wrong')).to be false
    end
  end

  describe 'scopes' do
    before do
      create(:merchant, status: 'active')
      create(:merchant, status: 'inactive')
    end

    it '.active returns only active merchants' do
      expect(Merchant.active.map(&:status)).to all(eq('active'))
    end

    it '.inactive returns only inactive merchants' do
      expect(Merchant.inactive.map(&:status)).to all(eq('inactive'))
    end
  end

  describe 'predicate methods' do
    it '#active? returns true when status is active' do
      merchant.status = 'active'
      expect(merchant.active?).to be true
    end

    it '#active? returns false when status is inactive' do
      merchant.status = 'inactive'
      expect(merchant.active?).to be false
    end

    it '#inactive? returns true when status is inactive' do
      merchant.status = 'inactive'
      expect(merchant.inactive?).to be true
    end

    it '#inactive? returns false when status is active' do
      merchant.status = 'active'
      expect(merchant.inactive?).to be false
    end
  end

  describe 'audit logging' do
    it 'logs a status change' do
      merchant = create(:merchant, status: 'active')
      expect { merchant.update!(status: 'inactive') }.to change(merchant.audit_logs, :count).by(1)
      expect(merchant.audit_logs.last.details).to eq('active -> inactive')
    end

    it 'does not log an update that leaves status unchanged' do
      merchant = create(:merchant, status: 'active')
      expect { merchant.update!(name: 'New Name') }.not_to change(merchant.audit_logs, :count)
    end
  end

  describe 'deletion protection' do
    it 'cannot be deleted when it has transactions' do
      merchant = create(:merchant)
      create(:authorize_transaction, merchant: merchant)
      expect { merchant.destroy }.not_to change(Merchant, :count)
      expect(merchant.errors[:base]).to be_present
    end

    it 'can be deleted when it has no transactions' do
      merchant = create(:merchant)
      expect { merchant.destroy }.to change(Merchant, :count).by(-1)
    end
  end
end
