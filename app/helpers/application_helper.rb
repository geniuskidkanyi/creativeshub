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
end
