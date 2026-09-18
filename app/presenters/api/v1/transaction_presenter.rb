# frozen_string_literal: true

module Api
  module V1
    class TransactionPresenter < ApplicationPresenter
      def to_h
        {
          uuid: entity.uuid,
          type: entity.type,
          status: entity.status,
          amount: entity.amount,
          customer_email: entity.customer_email,
          customer_phone: entity.customer_phone
        }
      end
    end
  end
end
