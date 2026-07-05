module Webhooks
  class ModemPayController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    skip_before_action :require_account!

    before_action :verify_modempay_signature

    def receive
      event_type = params[:event]
      payload = params[:payload]

      head :ok and return if event_type.blank? || payload.blank?

      event = WebhookEvent.find_or_initialize_by(event_id: payload[:id])

      if event.persisted? && event.processed?
        return head :ok
      end

      event.update!(
        event_type: event_type,
        payload: params.to_unsafe_h,
        status: :received
      )

      ActiveRecord::Base.transaction do
        process_event(event_type, payload)
        event.mark_processed!
      end

      head :ok
    rescue => e
      Rails.logger.error("ModemPay webhook error: #{e.message}")
      event&.mark_failed!
      head :ok
    end

    private

    def verify_modempay_signature
      signature = request.headers["x-modem-signature"]
      raw_body = request.raw_post

      unless ModemPayService.verify_signature(payload: raw_body, signature: signature)
        head :unauthorized
      end
    end

    def process_event(event_type, payload)
      case event_type
      when "charge.succeeded"
        process_charge_succeeded(payload)
      when "payment_intent.cancelled", "payment_intent.expired"
        process_payment_failed(payload)
      when /\Atransfer\./
        process_transfer_event(event_type, payload)
      end
    end

    def process_transfer_event(event_type, payload)
      payout = find_payout(payload)
      return unless payout

      status = case event_type
      when "transfer.completed", "transfer.succeeded" then :completed
      when "transfer.failed" then :failed
      when "transfer.flagged" then :flagged
      end
      return unless status

      payout.update!(
        status: status,
        transfer_reference: payload["transfer_reference"].presence || payout.transfer_reference,
        webhook_data: payload
      )
    end

    def find_payout(payload)
      payout_id = payload.dig("metadata", "payout_id")
      payout = Payout.find_by(id: payout_id) if payout_id
      payout || Payout.find_by(modempay_transfer_id: payload["id"])
    end

    def process_charge_succeeded(payload)
      payment = find_payment(payload)
      return unless payment

      payment.update!(
        status: :succeeded,
        transaction_reference: payload["transaction_reference"],
        paid_at: payload["updatedAt"] || Time.current,
        webhook_data: payload
      )
      return if payment.qr_payment?

      payment.invoice.mark_as_paid!(method: :payment_request, paid_at: payment.paid_at)
      InvoiceMailer.payment_received(payment).deliver_later
    end

    def process_payment_failed(payload)
      payment = find_payment(payload)
      return unless payment

      payment.update!(status: :failed, webhook_data: payload)
    end

    def find_payment(payload)
      payment_id = payload.dig("metadata", "payment_id")
      return nil unless payment_id

      Payment.find_by(id: payment_id)
    end
  end
end
