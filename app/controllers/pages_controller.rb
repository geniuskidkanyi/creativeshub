class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account!
  layout "landing"

  def about
  end

  def terms
  end

  def privacy
  end

  def faq
  end
end
