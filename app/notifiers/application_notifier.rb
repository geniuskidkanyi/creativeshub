# Base for all in-app + email notifications.
#
# Every notifier stores an in-app record (noticed always creates a
# Noticed::Notification per recipient) and, unless a recipient has no email,
# also sends an email. Subclasses set the params they need and implement
# `message`, `url`, and `icon` for rendering.
class ApplicationNotifier < Noticed::Event
  deliver_by :email do |config|
    config.mailer = "NotificationMailer"
    config.method = :notification
    # Evaluated in the delivery-method context, where `recipient` is available.
    config.if = -> { recipient.respond_to?(:email) && recipient.email.present? }
  end

  # Overridden by subclasses. `notification` is the per-recipient
  # Noticed::Notification, so copy can address the recipient if needed.
  def message(_notification = nil) = "You have a new notification"
  def url(_notification = nil) = "/dashboard"
  def icon = "bell"

  # A short category label shown in the UI and used for grouping/colour.
  def category = "general"
end
