# Google Analytics 4 measurement ID. Overridable per environment via
# GA_MEASUREMENT_ID; only actually rendered in production (see
# ApplicationHelper#google_analytics_enabled?) so dev/test don't pollute the
# property.
Rails.application.config.x.google_analytics_id = ENV.fetch("GA_MEASUREMENT_ID", "G-YLRP88MG03")
