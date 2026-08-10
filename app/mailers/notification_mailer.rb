# Generic email for any notifier. Noticed calls this with the per-recipient
# notification in params; the email renders the notifier's title/message and a
# link back into the app.
class NotificationMailer < ApplicationMailer
  def notification
    @notification = params[:notification]
    @recipient = params[:recipient]
    @event = @notification.event

    @action_url = absolute_url(@event.url)
    mail(to: @recipient.email, subject: @event.title)
  end

  private

  # Notifier URLs are app-relative paths; emails need absolute links.
  def absolute_url(path)
    return path if path.to_s.start_with?("http")

    options = ActionMailer::Base.default_url_options
    host = options[:host].presence || "smartpay.gm"
    protocol = options[:protocol].presence || "https"
    "#{protocol}://#{host}#{path}"
  end
end
