class ApplicationController < ActionController::Base
  include Tenantable
  include Pagy::Method

  layout :layout_by_controller

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # Queues a GA4 event to fire on the next rendered page. Stored in the flash
  # so it survives the redirect that follows most tracked actions (sign up,
  # log in). Event names/params come from our own code, never user input.
  def track_ga_event(name, params = {})
    events = flash[:ga_events] || []
    events << { "name" => name.to_s, "params" => params.stringify_keys }
    flash[:ga_events] = events
  end

  def layout_by_controller
    devise_controller? ? "landing" : "application"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def after_sign_in_path_for(resource)
    if resource.account.present?
      dashboard_path
    else
      new_account_path
    end
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end
end
