# frozen_string_literal: true

class AdminController < AuthenticatedController
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: "You are not authorized to view this page." unless current_user.admin?
  end
end
