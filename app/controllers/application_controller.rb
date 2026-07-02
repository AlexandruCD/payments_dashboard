# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Kept filter-free: Devise's own controllers inherit from this too, and a
  # global authenticate_user! here would redirect the sign-in page to itself.
  # See AuthenticatedController for pages that require a logged-in user.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
