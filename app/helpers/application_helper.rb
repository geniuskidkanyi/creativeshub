module ApplicationHelper
  def status_dot(status)
    case status.to_s
    when "paid" then "bg-emerald-500"
    when "sent" then "bg-indigo-400"
    when "overdue" then "bg-red-500"
    when "cancelled" then "bg-muted-foreground"
    else "bg-muted-foreground"
    end
  end

  def status_badge(status)
    case status.to_s
    when "paid" then "text-emerald-500 bg-emerald-500/15"
    when "sent" then "text-indigo-400 bg-indigo-400/15"
    when "overdue" then "text-red-500 bg-red-500/15"
    when "cancelled" then "text-muted-foreground bg-muted"
    else "text-muted-foreground bg-muted"
    end
  end

  def payment_qr_svg(account)
    url = qr_scan_url(token: account.qr_token, c: account.current_qr_code)
    RQRCode::QRCode.new(url).as_svg(
      color: "141a29",
      module_size: 5,
      standalone: true,
      use_path: true,
      viewbox: true
    )
  end

  def invoice_public_link(invoice)
    "#{Rails.configuration.x.public_host}/inv/#{invoice.public_token}"
  end

  # QR encoding the invoice's public payment page. Fixed module size (no
  # viewbox) so the SVG carries explicit dimensions — wkhtmltopdf's WebKit
  # needs those to size it in the PDF.
  def invoice_qr_svg(invoice, module_size: 3)
    RQRCode::QRCode.new(invoice_public_link(invoice)).as_svg(
      color: "141a29",
      module_size: module_size,
      standalone: true,
      use_path: true
    )
  end

  def payment_channel_label(channel)
    { "aps" => "APS", "qmoney" => "QMoney" }.fetch(channel.to_s.downcase, channel.to_s.titleize)
  end

  def payment_status_badge(status)
    case status.to_s
    when "succeeded" then "text-emerald-500 bg-emerald-500/15"
    when "pending" then "text-amber-500 bg-amber-500/15"
    when "failed" then "text-red-500 bg-red-500/15"
    else "text-muted-foreground bg-muted"
    end
  end

  def payout_status_badge(status)
    case status.to_s
    when "completed" then "text-emerald-500 bg-emerald-500/15"
    when "pending" then "text-amber-500 bg-amber-500/15"
    when "failed" then "text-red-500 bg-red-500/15"
    when "flagged" then "text-orange-500 bg-orange-500/15"
    else "text-muted-foreground bg-muted"
    end
  end

  # Inlines an asset-pipeline image as a data URI. PDFs need this: wkhtmltopdf
  # renders from a temp file, so /assets/... URLs don't resolve, and Active
  # Storage URL generation isn't available outside a request.
  def asset_data_uri(name)
    file = Rails.application.assets.load_path.find(name)
    return unless file

    mime = Marcel::MimeType.for(file.path)
    "data:#{mime};base64,#{Base64.strict_encode64(File.binread(file.path))}"
  end

  def base64_logo(account)
    return unless account.logo.attached?

    logo = account.logo.variant(resize_to_limit: [400, 160]).processed
    data = Base64.strict_encode64(logo.download)
    mime = logo.blob.content_type
    "data:#{mime};base64,#{data}"
  end

  def feature_icon(name)
    icons = {
      "globe" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
      "zap" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>',
      "shield" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
      "file" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>',
      "chart" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>',
      "sync" => '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/></svg>',
    }
    icons[name].html_safe
  end

  def status_pill_style(status)
    case status.to_s
    when "paid" then "background:#d1fae5;color:#065f46"
    when "sent" then "background:#fef9ec;color:#92400e"
    when "overdue" then "background:#fee2e2;color:#991b1b"
    when "cancelled" then "background:#f3f4f6;color:#6b7280"
    else "background:#fef9ec;color:#92400e"
    end
  end
end
