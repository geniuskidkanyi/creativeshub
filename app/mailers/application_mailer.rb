class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "SmartPay <noreply@smartpay.gm>")
  layout "mailer"
end
