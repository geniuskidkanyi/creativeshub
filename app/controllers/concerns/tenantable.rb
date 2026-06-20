module Tenantable
  extend ActiveSupport::Concern

  included do
    helper_method :current_account
    before_action :require_account!
  end

  protected

  def current_account
    @current_account ||= current_user&.account
  end

  def require_account!
    return unless user_signed_in?
    return if current_account.present?

    redirect_to new_account_path, alert: "Please create or join an account first."
  end
end
