# frozen_string_literal: true

module Api
  module V1
    class TokensController < Api::BaseController
      # Authentication only. Whether the merchant is active is checked when it
      # actually tries to submit a transaction, not at token issuance.
      def create
        merchant = Merchant.find_by(email: params[:email])

        if merchant&.authenticate(params[:password])
          render_payload({ token: JsonWebToken.encode(merchant_id: merchant.id) }, status: :created)
        else
          render_payload({ error: "invalid email or password" }, status: :unauthorized)
        end
      end
    end
  end
end
