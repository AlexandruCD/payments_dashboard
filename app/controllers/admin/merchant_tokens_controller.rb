# frozen_string_literal: true

module Admin
  class MerchantTokensController < AdminController
    def create
      @merchant = Merchant.find(params[:merchant_id])
      @issued_token = Merchants::IssueApiTokenService.call(merchant: @merchant).entity
      response.headers["Cache-Control"] = "no-store"
      render :create
    end
  end
end
