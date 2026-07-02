# frozen_string_literal: true

class AddReferencedTransactionToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :referenced_transaction_id, :integer
  end
end
