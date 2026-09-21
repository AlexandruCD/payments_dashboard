# frozen_string_literal: true

class ConvertUserRolesToSti < ActiveRecord::Migration[8.1]
  ROLE_TO_TYPE = {
    "admin" => "AdminUser",
    "merchant" => "MerchantUser"
  }.freeze

  def up
    assert_valid_roles!
    assert_merchants_belong_to_merchant_users!

    add_column :users, :type, :string
    ROLE_TO_TYPE.each do |role, type|
      execute <<~SQL.squish
        UPDATE users SET type = #{connection.quote(type)}
        WHERE role = #{connection.quote(role)}
      SQL
    end
    change_column_null :users, :type, false
    add_check_constraint :users, "type IN ('AdminUser', 'MerchantUser')", name: "users_type_allowed"
    add_index :users, :type
    remove_column :users, :role, :string, default: "merchant"
  end

  def down
    assert_valid_types!

    add_column :users, :role, :string, default: "merchant"
    ROLE_TO_TYPE.each do |role, type|
      execute <<~SQL.squish
        UPDATE users SET role = #{connection.quote(role)}
        WHERE type = #{connection.quote(type)}
      SQL
    end
    remove_check_constraint :users, name: "users_type_allowed"
    remove_index :users, :type
    remove_column :users, :type, :string
  end

  private

  def assert_valid_roles!
    invalid = select_values(<<~SQL.squish)
      SELECT DISTINCT COALESCE(role, 'NULL') FROM users
      WHERE role IS NULL OR role NOT IN ('admin', 'merchant')
    SQL
    return if invalid.empty?

    raise ActiveRecord::MigrationError, "Cannot migrate unknown user roles: #{invalid.join(', ')}"
  end

  def assert_merchants_belong_to_merchant_users!
    invalid_ids = select_values(<<~SQL.squish)
      SELECT merchants.id FROM merchants
      INNER JOIN users ON users.id = merchants.user_id
      WHERE users.role != 'merchant' OR users.role IS NULL
    SQL
    return if invalid_ids.empty?

    raise ActiveRecord::MigrationError,
          "Merchants reference non-merchant users: #{invalid_ids.join(', ')}"
  end

  def assert_valid_types!
    allowed_types = ROLE_TO_TYPE.values.map { |type| connection.quote(type) }.join(", ")
    invalid = select_values(<<~SQL.squish)
      SELECT DISTINCT COALESCE(type, 'NULL') FROM users
      WHERE type IS NULL OR type NOT IN (#{allowed_types})
    SQL
    return if invalid.empty?

    raise ActiveRecord::MigrationError, "Cannot restore unknown user types: #{invalid.join(', ')}"
  end
end
