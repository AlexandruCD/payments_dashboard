# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefundTransaction, type: :model do
  let(:authorize) { create(:authorize_transaction, status: 'approved', amount: 100) }
  let(:capture)   { create(:capture_transaction, referenced_transaction: authorize, amount: 100, status: 'approved') }
  subject(:transaction) { build(:refund_transaction, referenced_transaction: capture, amount: 50) }

  describe 'associations' do
    it { is_expected.to belong_to(:capture_transaction).class_name('CaptureTransaction') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }

    it 'is valid when referenced capture is approved' do
      expect(transaction).to be_valid
    end

    it 'is valid when referenced capture is refunded' do
      capture.update!(status: 'refunded')
      expect(transaction).to be_valid
    end

    it 'is invalid when referenced capture is error' do
      capture.update!(status: 'error')
      expect(transaction).not_to be_valid
      expect(transaction.errors[:referenced_transaction]).to be_present
    end

    it 'is invalid when referenced capture is pending' do
      capture.update!(status: 'pending')
      expect(transaction).not_to be_valid
    end
  end

  describe 'amount validation against captured amount' do
    it 'is invalid when amount exceeds captured amount' do
      transaction.amount = 101
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to be_present
    end

    it 'is valid when amount equals remaining captured amount' do
      transaction.amount = 100
      expect(transaction).to be_valid
    end

    it 'accounts for already refunded amounts' do
      create(:refund_transaction, referenced_transaction: capture, amount: 70, status: 'approved')
      transaction.amount = 31 # only 30 remaining
      expect(transaction).not_to be_valid
    end

    it 'allows multiple refunds as long as total does not exceed captured' do
      create(:refund_transaction, referenced_transaction: capture, amount: 70, status: 'approved')
      transaction.amount = 30
      expect(transaction).to be_valid
    end
  end
end
