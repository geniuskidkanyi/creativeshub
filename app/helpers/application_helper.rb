module ApplicationHelper
  def status_dot(status)
    case status.to_s
    when "paid" then "bg-accent"
    when "sent" then "bg-blue-400"
    when "overdue" then "bg-red-400"
    when "cancelled" then "bg-muted-foreground"
    else "bg-muted-foreground"
    end
  end

  def status_badge(status)
    case status.to_s
    when "paid" then "text-accent bg-accent/10"
    when "sent" then "text-blue-300 bg-blue-950/60"
    when "overdue" then "text-red-300 bg-red-950/60"
    when "cancelled" then "text-muted-foreground bg-muted"
    else "text-muted-foreground bg-muted"
    end
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
