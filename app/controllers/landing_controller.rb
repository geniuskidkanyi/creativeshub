class LandingController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account!
  layout "landing"

  def show
  end
end
