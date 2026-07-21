module WaveImporter
  # Dry run. Parses the upload and reports exactly what committing would do,
  # including which records already exist, so nothing is written to the
  # account until the numbers have been seen and accepted.
  class Previewer
    SAMPLE_SIZE = 25

    def initialize(account, kind:, path:)
      @account = account
      @kind = kind
      @path = path
    end

    def call
      case @kind
      when "customers" then preview_customers
      when "accounting" then preview_accounting
      else { "summary" => {}, "rows" => [], "warnings" => [ "This file type can't be imported yet." ] }
      end
    end

    private

    def preview_customers
      rows = CustomersParser.new(@path).call
      existing = @account.clients.where(external_source: "wave", external_ref: rows.map { |r| r.attributes[:external_ref] }).pluck(:external_ref).to_set

      {
        "summary" => {
          "Clients to create" => rows.count { |r| !existing.include?(r.attributes[:external_ref]) },
          "Existing clients to update" => rows.count { |r| existing.include?(r.attributes[:external_ref]) },
          "Without an email address" => rows.count { |r| r.attributes[:email].blank? },
          "Duplicates merged" => rows.count { |r| r.warnings.any? { |w| w.start_with?("Duplicate") } }
        },
        "rows" => rows.first(SAMPLE_SIZE).map do |row|
          {
            "name" => row.attributes[:name],
            "detail" => [ row.attributes[:company], row.attributes[:email], row.attributes[:phone] ].compact_blank.join(" · "),
            "status" => existing.include?(row.attributes[:external_ref]) ? "update" : "new",
            "warnings" => row.warnings
          }
        end,
        "total_rows" => rows.size,
        "warnings" => rows.flat_map(&:warnings).tally.map { |text, count| count > 1 ? "#{text} (#{count} rows)" : text }
      }
    end

    def preview_accounting
      parsed = AccountingParser.new(@path).call
      invoices = parsed[:invoices]
      existing = @account.invoices.where(external_source: "wave", external_ref: invoices.map(&:external_ref)).pluck(:external_ref).to_set
      known_products = @account.products.pluck(:name).to_set
      known_clients = @account.clients.where(external_source: "wave").pluck(:external_ref).to_set
      missing_clients = invoices.map(&:customer_ref).compact.uniq.reject { |ref| known_clients.include?(ref) }

      {
        "summary" => {
          "Invoices to create" => invoices.count { |i| !existing.include?(i.external_ref) },
          "Already imported (skipped)" => invoices.count { |i| existing.include?(i.external_ref) },
          "Line items" => invoices.sum { |i| i.items.size },
          "Products to create" => parsed[:products].count { |p| !known_products.include?(p[:name]) },
          "Marked paid" => invoices.count { |i| i.status == "paid" },
          "Clients created on the fly" => missing_clients.size
        },
        "rows" => invoices.sort_by { |i| i.issue_date || Date.new(1900) }.reverse.first(SAMPLE_SIZE).map do |invoice|
          {
            "name" => "#{invoice.external_ref} · #{invoice.customer_name}",
            "detail" => "#{invoice.issue_date} · D#{invoice.total.round(2)} · #{invoice.items.size} item#{'s' if invoice.items.size != 1}",
            "status" => existing.include?(invoice.external_ref) ? "skip" : invoice.status,
            "warnings" => invoice.warnings
          }
        end,
        "total_rows" => invoices.size,
        "total_value" => invoices.sum(&:total).round(2),
        "warnings" => build_warnings(invoices, missing_clients)
      }
    end

    def build_warnings(invoices, missing_clients)
      warnings = []
      partial = invoices.count { |i| i.warnings.any? { |w| w.start_with?("Partially paid") } }
      warnings << "#{partial} invoice#{'s' if partial != 1} were partially paid in Wave and import as unpaid — the part-payments are not carried over." if partial > 0
      warnings << "#{missing_clients.size} customer#{'s' if missing_clients.size != 1} appear on invoices but not in your clients — they'll be created automatically. Import customers.csv first for full contact details." if missing_clients.any?
      warnings << "Payment records are not created for paid invoices, so your payout balance is unaffected."
      warnings
    end
  end
end
