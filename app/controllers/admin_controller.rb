# frozen_string_literal: true

class AdminController < AuthenticatedController
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path, alert: I18n.t("admin.authorization.denied") unless current_user.admin?
  end
end
