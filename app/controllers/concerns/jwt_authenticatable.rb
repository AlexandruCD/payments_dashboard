# frozen_string_literal: true

module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_merchant!
    attr_reader :current_merchant
  end

  private

  def authenticate_merchant!
    payload = JsonWebToken.decode(bearer_token)
    @current_merchant = Merchant.find(payload[:merchant_id])

    render json: { error: "merchant is not active" }, status: :forbidden unless @current_merchant.active?
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "invalid or expired token" }, status: :unauthorized
  end

  def bearer_token
    request.headers["Authorization"]&.split(" ")&.last
  end
end
