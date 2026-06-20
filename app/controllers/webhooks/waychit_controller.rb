module Webhooks
  class WaychitController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    skip_before_action :require_account!

    before_action :verify_waychit_signature

    def receive
      event = WebhookEvent.find_or_initialize_by(event_id: params[:id])

      if event.persisted? && event.processed?
        return head :ok
      end

      event.update!(
        event_type: params[:type],
        payload: params.to_unsafe_h,
        status: :received
      )

      ActiveRecord::Base.transaction do
        process_event(params[:type], params[:data])
        event.mark_processed!
      end

      head :ok
    rescue => e
      Rails.logger.error("Waychit webhook error: #{e.message}")
      event&.mark_failed!
      head :ok
    end

    private

    def verify_waychit_signature
      signature = request.headers["Waychit-Signature"]
      raw_body = request.raw_post

      unless WaychitService.verify_signature(signature: signature, raw_body: raw_body)
        head :unauthorized
      end
    end

    def process_event(type, data)
      case type
      when "payment.request.completed"
        process_payment_request_completed(data)
      when "payment.session.completed"
        process_payment_session_completed(data)
      end
    end

    def process_payment_request_completed(data)
      client_reference = data["clientReference"]
      payment = Payment.find_by(id: client_reference)
      return unless payment

      if data["paymentStatus"] == "succeeded"
        payment.mark_succeeded!(
          transaction_ref: data["transactionReference"],
          paid_at: data["paidDate"]
        )
        payment.invoice.mark_as_paid!(
          method: :payment_request,
          paid_at: data["paidDate"]
        )
        InvoiceMailer.payment_received(payment).deliver_later
      end
    end

    def process_payment_session_completed(data)
      client_reference = data["clientReference"]
      payment = Payment.find_by(id: client_reference)
      return unless payment

      if data["paymentStatus"] == "succeeded"
        payment.mark_succeeded!(
          transaction_ref: data["transactionReference"],
          paid_at: data["paidDate"]
        )
        payment.invoice.mark_as_paid!(
          method: :payment_session,
          paid_at: data["paidDate"]
        )
        InvoiceMailer.payment_received(payment).deliver_later
      end
    end
  end
end
