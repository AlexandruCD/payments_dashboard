# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizeTransaction, type: :model do
  subject(:transaction) { build(:authorize_transaction) }

  describe 'associations' do
    it { is_expected.to have_many(:capture_transactions).class_name('CaptureTransaction') }
    it { is_expected.to have_many(:void_transactions).class_name('VoidTransaction') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:notification_url) }

    it 'is valid with valid attributes' do
      expect(transaction).to be_valid
    end

    it 'is invalid with a non-HTTP notification_url' do
      transaction.notification_url = 'ftp://example.com/notify'
      expect(transaction).not_to be_valid
      expect(transaction.errors[:notification_url]).to be_present
    end

    it 'is invalid with a malformed notification_url' do
      transaction.notification_url = 'not a url'
      expect(transaction).not_to be_valid
    end

    it 'is valid with an https notification_url' do
      transaction.notification_url = 'https://example.com/notify'
      expect(transaction).to be_valid
    end

    it 'is invalid without amount' do
      transaction.amount = nil
      expect(transaction).not_to be_valid
    end
  end

  describe '#total_captured' do
    let(:authorize) { create(:authorize_transaction, amount: 100, status: 'approved') }

    it 'returns 0 when no captures exist' do
      expect(authorize.total_captured).to eq(0)
    end

    it 'sums approved capture transactions' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 30, status: 'approved')
      create(:capture_transaction, referenced_transaction: authorize, amount: 20, status: 'approved')
      expect(authorize.total_captured).to eq(50)
    end

    it 'does not count error capture transactions' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 30, status: 'error')
      expect(authorize.total_captured).to eq(0)
    end
  end

  describe '#fully_captured?' do
    let(:authorize) { create(:authorize_transaction, amount: 100, status: 'approved') }

    it 'returns false when not fully captured' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 50, status: 'approved')
      expect(authorize.fully_captured?).to be false
    end

    it 'returns true when fully captured' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 100, status: 'approved')
      expect(authorize.fully_captured?).to be true
    end
  end

  describe 'status' do
    it 'is created with pending status' do
      transaction = create(:authorize_transaction)
      expect(transaction.status).to eq('pending')
    end
  end
end
