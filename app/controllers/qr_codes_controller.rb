class QrCodesController < ApplicationController
  def show
    @account = current_account
    @account.update_columns(qr_token: SecureRandom.urlsafe_base64(12)) if @account.qr_token.blank?
    @account.update_columns(qr_secret: SecureRandom.hex(32)) if @account.qr_secret.blank?

    @scan_url = scan_url_for(@account)
    @qr_svg = qr_svg_for(@scan_url)
    @seconds_remaining = @account.qr_seconds_remaining

    respond_to do |format|
      format.html
      format.json do
        render json: { svg: @qr_svg, scan_url: @scan_url, seconds_remaining: @seconds_remaining }
      end
    end
  end

  private

  def scan_url_for(account)
    qr_scan_url(token: account.qr_token, c: account.current_qr_code)
  end

  def qr_svg_for(url)
    RQRCode::QRCode.new(url).as_svg(
      color: "141a29",
      module_size: 5,
      standalone: true,
      use_path: true,
      viewbox: true
    )
  end
end
