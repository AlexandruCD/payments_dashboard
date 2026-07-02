# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :uuid
      t.decimal :amount
      t.string :status
      t.string :customer_email
      t.string :customer_phone
      t.string :notification_url
      t.string :type
      t.references :merchant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
