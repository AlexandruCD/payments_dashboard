# frozen_string_literal: true

module Admin
  class MerchantUsersController < AdminController
    def create
      @merchant = Merchant.find(params[:merchant_id])
      @merchant_user_form = MerchantUserForm.new(merchant: @merchant, attributes: merchant_user_form_params)

      if @merchant_user_form.save
        redirect_to admin_merchant_path(@merchant), notice: I18n.t("admin.merchant_users.flashes.created")
      else
        @transactions = @merchant.transactions.order(created_at: :desc).map { |t| TransactionPresenter.new(t) }
        render "admin/merchants/show", status: :unprocessable_content
      end
    end

    private

    def merchant_user_form_params
      params.require(:merchant_user_form).permit(:email, :password)
    end
  end
end
