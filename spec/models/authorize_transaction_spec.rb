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

  describe 'state machine' do
    it 'starts pending' do
      expect(transaction).to be_pending
    end

    it 'processes pending authorizations to approved or error' do
      expect(transaction).to be_may_approve
      expect(transaction).to be_may_mark_failed
    end

    it 'captures an approved authorization and permits later partial captures' do
      transaction.status = 'approved'

      expect { transaction.capture }.to change(transaction, :status).from('approved').to('captured')
      expect(transaction).to be_may_capture
      expect { transaction.capture }.not_to change(transaction, :status)
    end

    it 'voids only an approved authorization' do
      transaction.status = 'approved'

      expect { transaction.void }.to change(transaction, :status).from('approved').to('voided')
      expect(transaction).not_to be_may_capture
      expect(transaction).not_to be_may_void
    end

    it 'rejects statuses outside the authorization lifecycle' do
      transaction.status = 'refunded'

      expect(transaction).not_to be_valid
      expect(transaction.errors[:status]).to include('is invalid')
    end

    it 'provides a pending scope for the stale authorization sweep' do
      pending = create(:authorize_transaction)
      create(:authorize_transaction, status: 'approved')

      expect(described_class.pending).to contain_exactly(pending)
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
