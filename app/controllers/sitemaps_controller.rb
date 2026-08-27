class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account!
  layout false

  # Only public, indexable URLs belong here. The app itself is behind login and
  # invoice links are private tokens, so the marketing homepage is the sitemap.
  def show
    host = Rails.configuration.x.public_host
    # Trailing slash to match the homepage canonical URL exactly.
    @pages = [
      { loc: "#{host}/", changefreq: "weekly", priority: "1.0" }
    ]
    render formats: :xml
  end
end
