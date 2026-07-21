module WaveImporter
  # Wave's exports have no file-type marker beyond their headers, and users
  # rename downloads freely — so the file is identified by which headers it
  # carries rather than by its name.
  class FileDetector
    SIGNATURES = {
      "customers" => %w[customer_name customer_currency],
      "vendors" => %w[vendor_name vendor_currency],
      "bill_items" => %w[vendor bill_date],
      "accounting" => [ "Transaction ID", "Account Name" ]
    }.freeze

    # Wave writes UTF-8 with accented account names ("Computer – Internet")
    # and sometimes a BOM. Reading as anything else raises mid-parse.
    ENCODING = "bom|utf-8".freeze

    def self.detect(path)
      headers = CSV.open(path, headers: true, encoding: ENCODING, &:readline)&.headers.to_a.compact
      kind = SIGNATURES.find { |_, required| required.all? { |h| headers.include?(h) } }&.first
      { kind: kind, headers: headers }
    rescue CSV::MalformedCSVError, ArgumentError => e
      { kind: nil, headers: [], error: e.message }
    end
  end
end
