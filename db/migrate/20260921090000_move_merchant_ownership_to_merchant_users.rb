# frozen_string_literal: true

class MoveMerchantOwnershipToMerchantUsers < ActiveRecord::Migration[8.1]
  def up
    assert_current_links_are_valid!

    add_column :users, :merchant_id, :bigint
    execute <<~SQL.squish
      UPDATE users
      SET merchant_id = merchants.id
      FROM merchants
      WHERE merchants.user_id = users.id
    SQL
    add_index :users, :merchant_id, unique: true
    add_foreign_key :users, :merchants
    add_check_constraint :users, merchant_link_constraint, name: "users_merchant_link_matches_type"

    remove_foreign_key :merchants, :users
    remove_index :merchants, :user_id
    remove_column :merchants, :user_id, :bigint
  end

  def down
    assert_every_merchant_has_a_user!

    add_column :merchants, :user_id, :bigint
    execute <<~SQL.squish
      UPDATE merchants
      SET user_id = users.id
      FROM users
      WHERE users.merchant_id = merchants.id
    SQL
    change_column_null :merchants, :user_id, false
    add_index :merchants, :user_id, unique: true
    add_foreign_key :merchants, :users

    remove_check_constraint :users, name: "users_merchant_link_matches_type"
    remove_foreign_key :users, :merchants
    remove_index :users, :merchant_id
    remove_column :users, :merchant_id, :bigint
  end

  private

  def merchant_link_constraint
    <<~SQL.squish
      (type = 'MerchantUser' AND merchant_id IS NOT NULL) OR
      (type = 'AdminUser' AND merchant_id IS NULL)
    SQL
  end

  def assert_current_links_are_valid!
    orphan_user_ids = select_values(<<~SQL.squish)
      SELECT users.id
      FROM users
      LEFT JOIN merchants ON merchants.user_id = users.id
      WHERE users.type = 'MerchantUser' AND merchants.id IS NULL
    SQL
    invalid_merchant_ids = select_values(<<~SQL.squish)
      SELECT merchants.id
      FROM merchants
      INNER JOIN users ON users.id = merchants.user_id
      WHERE users.type != 'MerchantUser' OR users.type IS NULL
    SQL
    return if orphan_user_ids.empty? && invalid_merchant_ids.empty?

    details = []
    details << "MerchantUsers without merchants: #{orphan_user_ids.join(', ')}" if orphan_user_ids.any?
    details << "Merchants linked to non-MerchantUsers: #{invalid_merchant_ids.join(', ')}" if invalid_merchant_ids.any?
    raise ActiveRecord::MigrationError, "Cannot move merchant ownership. #{details.join('; ')}"
  end

  def assert_every_merchant_has_a_user!
    merchant_ids = select_values(<<~SQL.squish)
      SELECT merchants.id
      FROM merchants
      LEFT JOIN users
        ON users.merchant_id = merchants.id AND users.type = 'MerchantUser'
      WHERE users.id IS NULL
    SQL
    return if merchant_ids.empty?

    raise ActiveRecord::MigrationError,
          "Cannot restore required merchant users for merchants: #{merchant_ids.join(', ')}"
  end
end
