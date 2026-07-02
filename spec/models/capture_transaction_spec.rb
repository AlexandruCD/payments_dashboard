# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaptureTransaction, type: :model do
  let(:authorize) { create(:authorize_transaction, status: 'approved', amount: 100) }
  subject(:transaction) { build(:capture_transaction, referenced_transaction: authorize, amount: 50) }

  describe 'associations' do
    it { is_expected.to belong_to(:authorize_transaction).class_name('AuthorizeTransaction') }
    it { is_expected.to have_many(:refund_transactions).class_name('RefundTransaction') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }

    it 'is valid when referenced authorize is approved' do
      expect(transaction).to be_valid
    end

    it 'is valid when referenced authorize is captured' do
      authorize.update!(status: 'captured')
      expect(transaction).to be_valid
    end

    it 'is invalid when referenced authorize is voided' do
      authorize.update!(status: 'voided')
      expect(transaction).not_to be_valid
      expect(transaction.errors[:referenced_transaction]).to be_present
    end

    it 'is invalid when referenced authorize is pending' do
      authorize.update!(status: 'pending')
      expect(transaction).not_to be_valid
    end

    it 'is invalid when referenced authorize is error' do
      authorize.update!(status: 'error')
      expect(transaction).not_to be_valid
    end
  end

  describe 'amount validation against authorized amount' do
    it 'is invalid when amount exceeds remaining authorized amount' do
      transaction.amount = 101
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to be_present
    end

    it 'is valid when amount equals remaining authorized amount' do
      transaction.amount = 100
      expect(transaction).to be_valid
    end

    it 'accounts for already captured amounts' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 70, status: 'approved')
      transaction.amount = 31 # only 30 remaining
      expect(transaction).not_to be_valid
    end

    it 'allows multiple captures as long as total does not exceed authorized' do
      create(:capture_transaction, referenced_transaction: authorize, amount: 70, status: 'approved')
      transaction.amount = 30
      expect(transaction).to be_valid
    end
  end

  describe '#total_refunded' do
    let(:capture) { create(:capture_transaction, referenced_transaction: authorize, amount: 100, status: 'approved') }

    it 'returns 0 when no refunds exist' do
      expect(capture.total_refunded).to eq(0)
    end

    it 'sums approved refund transactions' do
      create(:refund_transaction, referenced_transaction: capture, amount: 40, status: 'approved')
      create(:refund_transaction, referenced_transaction: capture, amount: 20, status: 'approved')
      expect(capture.total_refunded).to eq(60)
    end

    it 'does not count error refund transactions' do
      create(:refund_transaction, referenced_transaction: capture, amount: 40, status: 'error')
      expect(capture.total_refunded).to eq(0)
    end
  end
end
