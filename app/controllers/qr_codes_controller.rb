class QrCodesController < ApplicationController
  def show
    @account = current_account
    @account.update_columns(qr_token: SecureRandom.urlsafe_base64(12)) if @account.qr_token.blank?
    @account.update_columns(qr_secret: SecureRandom.hex(32)) if @account.qr_secret.blank?

    respond_to do |format|
      format.html
      format.json do
        render json: {
          svg: helpers.payment_qr_svg(@account),
          seconds_remaining: @account.qr_seconds_remaining
        }
      end
    end
  end
end
