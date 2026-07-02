# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Kept filter-free: Devise's own controllers inherit from this too, and a
  # global authenticate_user! here would redirect the sign-in page to itself.
  # See AuthenticatedController for pages that require a logged-in user.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Devise's own default (root_path) is itself auth-protected, so signing out
  # would immediately bounce again through authenticate_user!, swallowing the
  # "Signed out successfully" flash under a second "You need to sign in" one.
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
