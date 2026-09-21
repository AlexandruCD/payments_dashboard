# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject(:transaction) { build(:authorize_transaction) }

  describe 'associations' do
    it { is_expected.to belong_to(:merchant) }

    it 'keeps follow-up references out of the base class' do
      expect(described_class.reflect_on_association(:referenced_transaction)).to be_nil
    end
  end

  describe 'validations' do
    # nil is auto-filled by a before_validation callback, so use a blank string instead
    it 'is invalid with a blank uuid' do
      transaction.uuid = ''
      expect(transaction).not_to be_valid
    end

    it { is_expected.to validate_uniqueness_of(:uuid) }
    it { is_expected.to validate_presence_of(:customer_email) }

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

  describe 'audit logging' do
    it 'logs a status change' do
      authorize = create(:authorize_transaction)

      expect { authorize.approve! }.to change(authorize.audit_logs, :count).by(1)
      expect(authorize.audit_logs.last.details).to eq('pending -> approved')
    end

    it 'does not log an update that leaves status unchanged' do
      authorize = create(:authorize_transaction, status: 'approved')
      expect { authorize.update!(customer_phone: '+15559990000') }.not_to change(authorize.audit_logs, :count)
    end
  end
end
