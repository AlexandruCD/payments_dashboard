# frozen_string_literal: true

module Admin
  class MerchantsController < AdminController
    before_action :set_merchant, only: %i[show edit update destroy]

    def index
      @merchants = Merchant.all.map { |merchant| MerchantPresenter.new(merchant) }
    end

    def show
      load_show_data
    end

    def new
      @form = MerchantForm.new
    end

    def create
      @form = MerchantForm.new(merchant_form_params)

      if @form.save
        redirect_to admin_merchant_path(@form.merchant), notice: I18n.t("admin.merchants.flashes.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      result = Merchants::UpdateService.call(merchant: @merchant, params: merchant_params)

      if result.success?
        redirect_to admin_merchant_path(@merchant), notice: I18n.t("admin.merchants.flashes.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @merchant.destroy
        redirect_to admin_merchants_path, notice: I18n.t("admin.merchants.flashes.deleted")
      else
        redirect_to admin_merchant_path(@merchant), alert: @merchant.errors.full_messages.to_sentence
      end
    end

    private

    def set_merchant
      @merchant = Merchant.find(params[:id])
    end

    def merchant_params
      params.require(:merchant).permit(:name, :description, :email, :status)
    end

    def merchant_form_params
      params.require(:merchant_form).permit(:name, :description, :email, :status)
    end

    def load_show_data
      @transactions = @merchant.transactions.order(created_at: :desc).map { |t| TransactionPresenter.new(t) }
      @merchant_user_form = MerchantUserForm.new(merchant: @merchant) unless @merchant.merchant_user
    end
  end
end
