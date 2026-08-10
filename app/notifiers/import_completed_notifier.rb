# Fires when a Wave import finishes (or fails) — closes the "did it work?"
# loop for an import the user may have navigated away from.
class ImportCompletedNotifier < ApplicationNotifier
  required_param :wave_import

  def wave_import = params[:wave_import]

  def title = wave_import.failed? ? "Import failed" : "Import complete"

  def message(_notification = nil)
    return "Your #{wave_import.label.downcase} import couldn't be completed." if wave_import.failed?

    result = wave_import.result
    parts = {
      "clients" => result["clients_created"].to_i,
      "invoices" => result["invoices_created"].to_i,
      "products" => result["products_created"].to_i
    }.select { |_, count| count.positive? }.map { |label, count| "#{count} #{label}" }

    parts.any? ? "Imported #{parts.join(', ')}." : "Your import finished."
  end

  def url(_notification = nil) = Rails.application.routes.url_helpers.import_path(wave_import)

  def icon = wave_import.failed? ? "alert" : "check"
  def category = wave_import.failed? ? "alert" : "import"
end
