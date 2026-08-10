class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice)
    @invoice = invoice
    @account = invoice.account
    @client = invoice.client
    # Absolute URL of the 1x1 open-tracking pixel embedded in the email body.
    @open_url = "#{Rails.configuration.x.public_host}/inv/#{invoice.public_token}/open"

    # Inline (CID) so logos render even when the client blocks remote images.
    # The business's own logo leads the email; SmartPay is the footer credit.
    attach_business_logo(@account)
    attachments.inline["smartpay-logo.png"] = File.binread(Rails.root.join("app/assets/images/smart-pay-logo.png"))
    attachments["#{invoice.invoice_number}.pdf"] = generate_pdf(invoice)

    mail(
      to: @client.email,
      subject: "Invoice #{invoice.invoice_number} from #{@account.business_name}"
    )
  end

  def payment_received(payment)
    @payment = payment
    @invoice = payment.invoice
    @account = @invoice.account

    mail(
      to: @invoice.client.email,
      subject: "Payment received for Invoice #{@invoice.invoice_number}"
    )
  end

  private

  # Attaches the account's uploaded logo inline as "business-logo" (referenced
  # by cid in the view). Best-effort: a logo problem must never block sending
  # the invoice — the view falls back to the business name.
  def attach_business_logo(account)
    return unless account.logo.attached?

    variant = account.logo.variant(resize_to_limit: [ 400, 160 ]).processed
    attachments.inline["business-logo"] = {
      mime_type: account.logo.blob.content_type,
      content: variant.download
    }
  rescue StandardError => e
    Rails.logger.warn "Invoice email: business logo attach failed for account #{account.id}: #{e.class}: #{e.message}"
  end

  def generate_pdf(invoice)
    WickedPdf.new.pdf_from_string(
      ApplicationController.render(
        template: "invoices/show",
        formats: [ :pdf ],
        layout: "pdf",
        assigns: { invoice: invoice }
      )
    )
  end
end
