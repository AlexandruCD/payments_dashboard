# frozen_string_literal: true

class AddPasswordDigestToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :password_digest, :string
  end
end
