# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject(:transaction) { build(:authorize_transaction) }

  describe 'associations' do
    it { is_expected.to belong_to(:merchant) }
    it { is_expected.to belong_to(:referenced_transaction).class_name('Transaction').optional }
  end

  describe 'validations' do
    # nil is auto-filled by a before_validation callback, so use a blank string instead
    it 'is invalid with a blank uuid' do
      transaction.uuid = ''
      expect(transaction).not_to be_valid
    end

    it { is_expected.to validate_uniqueness_of(:uuid) }
    it { is_expected.to validate_presence_of(:customer_email) }

    it 'is invalid with a blank status' do
      transaction.status = ''
      expect(transaction).not_to be_valid
    end

    it { is_expected.to validate_inclusion_of(:status).in_array(Transaction::STATUSES) }

    it 'validates customer_email format' do
      transaction.customer_email = 'not-an-email'
      expect(transaction).not_to be_valid
      expect(transaction.errors[:customer_email]).to be_present
    end

    it 'accepts valid customer_email' do
      transaction.customer_email = 'user@example.com'
      expect(transaction).to be_valid
    end

    it 'validates amount is greater than 0 when present' do
      transaction.amount = -1
      expect(transaction).not_to be_valid
    end

    it 'allows nil amount on base class' do
      transaction.amount = nil
      expect(transaction.errors[:amount]).to be_empty
    end
  end

  describe 'uuid auto-generation' do
    it 'generates a uuid before validation on create' do
      transaction.uuid = nil
      transaction.valid?
      expect(transaction.uuid).to be_present
    end

    it 'does not overwrite an existing uuid' do
      existing = 'my-custom-uuid'
      transaction.uuid = existing
      transaction.valid?
      expect(transaction.uuid).to eq(existing)
    end
  end

  describe 'predicate methods' do
    Transaction::STATUSES.each do |s|
      it "responds to #{s}?" do
        transaction.status = s
        expect(transaction.public_send(:"#{s}?")).to be true
      end

      it "returns false for #{s}? when status is different" do
        other_status = (Transaction::STATUSES - [ s ]).first
        transaction.status = other_status
        expect(transaction.public_send(:"#{s}?")).to be false
      end
    end
  end

  describe 'audit logging' do
    it 'logs a status change' do
      authorize = create(:authorize_transaction, status: 'approved')
      expect { authorize.update!(status: 'voided') }.to change(authorize.audit_logs, :count).by(1)
      expect(authorize.audit_logs.last.details).to eq('approved -> voided')
    end

    it 'does not log an update that leaves status unchanged' do
      authorize = create(:authorize_transaction, status: 'approved')
      expect { authorize.update!(customer_phone: '+15559990000') }.not_to change(authorize.audit_logs, :count)
    end
  end

  describe 'scopes' do
    let(:merchant) { create(:merchant) }

    before do
      create(:authorize_transaction, merchant: merchant)
      Transaction::STATUSES.each do |s|
        next if s == 'pending' # already created above
        create(:authorize_transaction, merchant: merchant, status: s) if s == 'approved'
        create(:capture_transaction, merchant: merchant, status: s) if s == 'captured'
        create(:void_transaction, merchant: merchant, status: s) if s == 'voided'
        create(:refund_transaction, merchant: merchant, status: s) if s == 'refunded'
      end
      create(:authorize_transaction, merchant: merchant, status: 'error')
    end

    it '.pending returns only pending transactions' do
      expect(Transaction.pending.map(&:status)).to all(eq('pending'))
    end

    it '.approved returns only approved transactions' do
      expect(Transaction.approved.map(&:status)).to all(eq('approved'))
    end

    it '.captured returns only captured transactions' do
      expect(Transaction.captured.map(&:status)).to all(eq('captured'))
    end

    it '.voided returns only voided transactions' do
      expect(Transaction.voided.map(&:status)).to all(eq('voided'))
    end

    it '.refunded returns only refunded transactions' do
      expect(Transaction.refunded.map(&:status)).to all(eq('refunded'))
    end

    it '.error returns only error transactions' do
      expect(Transaction.error.map(&:status)).to all(eq('error'))
    end
  end
end
