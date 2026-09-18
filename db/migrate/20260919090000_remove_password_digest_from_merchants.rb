# frozen_string_literal: true

class RemovePasswordDigestFromMerchants < ActiveRecord::Migration[8.1]
  def change
    remove_column :merchants, :password_digest, :string
  end
end
