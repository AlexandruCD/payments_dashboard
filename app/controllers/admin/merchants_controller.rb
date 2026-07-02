# frozen_string_literal: true

module Admin
  class MerchantsController < AdminController
    before_action :set_merchant, only: %i[show edit update destroy]

    def index
      @merchants = Merchant.all.map { |merchant| MerchantPresenter.new(merchant) }
    end

    def show
      @transactions = @merchant.transactions.order(created_at: :desc).map { |t| TransactionPresenter.new(t) }
    end

    def new
      @form = MerchantRegistrationForm.new
    end

    def create
      @form = MerchantRegistrationForm.new(merchant_registration_params)

      if @form.save
        redirect_to admin_merchant_path(@form.merchant), notice: "Merchant created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @merchant.update(merchant_params)
        redirect_to admin_merchant_path(@merchant), notice: "Merchant updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @merchant.destroy
        redirect_to admin_merchants_path, notice: "Merchant deleted."
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

    def merchant_registration_params
      params.require(:merchant_registration_form)
            .permit(:name, :description, :email, :status, :password, :user_email, :user_password)
    end
  end
end
