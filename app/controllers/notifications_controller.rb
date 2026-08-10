class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :read ]

  def index
    scope = current_user.notifications.includes(:event).order(created_at: :desc)
    @pagy, @notifications = pagy(scope, limit: 20)
    @unread_count = current_user.notifications.unread.count
  end

  # Marks one read and forwards to wherever it points (an invoice, payouts…).
  def read
    @notification.update!(read_at: Time.current) if @notification.read_at.nil?
    redirect_to safe_target(@notification), allow_other_host: false
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  # Only follow in-app paths; never trust a notifier URL to leave the site.
  def safe_target(notification)
    url = notification.event.url.to_s
    url.start_with?("/") ? url : notifications_path
  end
end
