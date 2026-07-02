# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    private

    # JSON by default; XML only when explicitly requested (Accept header or .xml extension).
    def render_payload(body, status:)
      if request.format.xml?
        render xml: body, status: status
      else
        render json: body, status: status
      end
    end
  end
end
