# frozen_string_literal: true

class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name
      t.text :description
      t.string :email
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
