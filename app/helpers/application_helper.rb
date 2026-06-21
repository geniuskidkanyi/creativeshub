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
