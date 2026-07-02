# frozen_string_literal: true

class AddMissingUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :merchants, :user_id
    add_index :merchants, :user_id, unique: true

    add_index :transactions, :uuid, unique: true
  end
end
