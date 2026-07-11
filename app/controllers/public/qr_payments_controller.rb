class Public::QrPaymentsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account!

  before_action :set_account

  # A scan pass keeps the payment form usable after a valid scan, matching the
  # in-use window a scanned QR code gets.
  SCAN_PASS_VALIDITY = QrScan::IN_USE_WINDOW

  def show
    # Revisiting a scan link whose payment already succeeded shows the payment
    # status instead of a fresh payment form (checked before code verification
    # so it also beats the expired page). Paying again requires a new scan.
    if (@payment = completed_scan_payment)
      return render :complete
    end

    unless @account.verify_qr_code(params[:c])
      return render :expired, status: :gone
    end

    @scan_pass = scan_pass_verifier.generate(
      { account_id: @account.id, code: params[:c] },
      expires_in: SCAN_PASS_VALIDITY
    )
  end

  def create
    pass = scan_pass_verifier.verified(params[:scan_pass])
    unless pass && pass["account_id"] == @account.id
      return render :expired, status: :gone
    end

    # Starting a payment counts as using the code: extend its in-use window so
    # it is still honored when the customer comes back from Modem Pay.
    @account.verify_qr_code(pass["code"])

    amount = params[:amount].to_d
    if amount < 10
      flash.now[:alert] = "Please enter an amount of at least D10."
      @scan_pass = params[:scan_pass]
      return render :show, status: :unprocessable_entity
    end

    payment = @account.payments.create!(
      status: :pending,
      amount: amount,
      currency: "GMD",
      payment_method: "payment_session",
      note: params[:note].to_s.strip.first(80).presence
    )

    return_url = "#{Rails.configuration.x.public_host}/scan/#{@account.qr_token}/complete?p=#{payment_pass(payment)}"

    result = ModemPayService.create_payment(
      amount: amount.to_i,
      currency: "GMD",
      description: "Payment to #{@account.business_name}#{payment.note ? " — #{payment.note}" : ""}",
      metadata: { payment_id: payment.id.to_s, account_id: @account.id.to_s, qr: "true" },
      return_url: return_url,
      cancel_url: return_url,
      sub_account: @account.modempay_sub_account_id.presence
    )

    if result.success?
      payment.update!(waychit_id: result.payment_intent_id, metadata: result.raw_response)
      # Remember which code this browser paid with, so revisiting that scan
      # link shows the payment status rather than another payment form.
      session[:qr_payment] = { "id" => payment.id, "step" => code_step(pass["code"]) }
      redirect_to result.payment_link, allow_other_host: true
    else
      payment.destroy
      Rails.logger.error "ModemPay QR payment init failed: #{result.error}"
      flash.now[:alert] = "Payment could not be started: #{result.error}"
      @scan_pass = params[:scan_pass]
      render :show, status: :unprocessable_entity
    end
  end

  def complete
    # Some gateways append their own query string to the return_url with a
    # bare "?", which lands inside the p param — keep only the pass itself.
    pass = params[:p].to_s.split(/[?&]/).first
    payment_id = scan_pass_verifier.verified(pass)&.fetch("payment_id", nil)
    @payment = payment_id && @account.payments.find_by(id: payment_id)
    return redirect_to qr_scan_path(token: @account.qr_token) unless @payment
  end

  private

  def set_account
    @account = Account.find_by!(qr_token: params[:token])
  end

  def scan_pass_verifier
    Rails.application.message_verifier(:qr_scan)
  end

  def payment_pass(payment)
    scan_pass_verifier.generate({ payment_id: payment.id }, expires_in: 1.hour)
  end

  # The succeeded payment this browser made against the code in the URL, if
  # any. A re-scan produces a new code (new step), which won't match and so
  # falls through to the normal payment form.
  def completed_scan_payment
    tracked = session[:qr_payment]
    return unless tracked.is_a?(Hash) && tracked["step"].present?
    return unless code_step(params[:c]) == tracked["step"]

    @account.payments.succeeded.find_by(id: tracked["id"])
  end

  def code_step(code)
    step = code.to_s.split("-", 2).first
    step if step =~ /\A\d+\z/
  end
end
