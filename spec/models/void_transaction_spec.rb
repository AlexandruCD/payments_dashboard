# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VoidTransaction, type: :model do
  let(:authorize) { create(:authorize_transaction, status: 'approved', amount: 100) }
  subject(:transaction) { build(:void_transaction, referenced_transaction: authorize) }

  describe 'associations' do
    it { is_expected.to belong_to(:authorize_transaction).class_name('AuthorizeTransaction') }
  end

  describe 'validations' do
    it 'is valid when referenced authorize is approved' do
      expect(transaction).to be_valid
    end

    it 'is invalid when referenced authorize is pending' do
      authorize.update!(status: 'pending')
      expect(transaction).not_to be_valid
      expect(transaction.errors[:referenced_transaction]).to be_present
    end

    it 'is invalid when referenced authorize is captured' do
      authorize.update!(status: 'captured')
      expect(transaction).not_to be_valid
    end

    it 'is invalid when referenced authorize is voided' do
      authorize.update!(status: 'voided')
      expect(transaction).not_to be_valid
    end

    it 'is invalid when referenced authorize is error' do
      authorize.update!(status: 'error')
      expect(transaction).not_to be_valid
    end

    it 'does not require an amount' do
      transaction.amount = nil
      expect(transaction).to be_valid
    end
  end
end
