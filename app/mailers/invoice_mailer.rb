class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice)
    @invoice = invoice
    @account = invoice.account
    @client = invoice.client

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
