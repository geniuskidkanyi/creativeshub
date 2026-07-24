module WaveImporter
  # Turns Wave's customers.csv into Client attributes.
  #
  # Two things make this more than a column mapping:
  #
  # 1. Email is not an identity. In a real export a single address can sit on
  #    a dozen customers (an agency's shared inbox), so matching on email
  #    would merge unrelated businesses. Identity is the normalized name.
  # 2. Wave lets the same customer exist twice with different casing or
  #    trailing whitespace ("i-Link" / "I-link"). Those collapse into one
  #    client and are reported, rather than failing the unique index at
  #    commit time.
  class CustomersParser
    Row = Struct.new(:attributes, :warnings, :line, keyword_init: true)

    def initialize(path)
      @path = path
    end

    def call
      rows = []
      seen = {}

      FileDetector.table(@path).each.with_index(2) do |csv_row, line|
        name = squish(csv_row["customer_name"])
        next if name.blank?

        key = name.downcase
        attributes = build_attributes(csv_row, name)
        warnings = []

        if (first_line = seen[key])
          warnings << "Duplicate of the customer on line #{first_line} — will be merged"
          existing = rows.find { |r| r.attributes[:external_ref] == key }
          merge_into(existing, attributes) if existing
          existing.warnings.concat(warnings) if existing
          next
        end

        seen[key] = line
        warnings << "No email on file — invoices will be shared by link" if attributes[:email].blank?
        warnings << "Email is not a valid address and was dropped" if dropped_email?(csv_row)

        rows << Row.new(attributes: attributes, warnings: warnings, line: line)
      end

      rows
    end

    private

    def build_attributes(csv_row, name)
      contact = contact_name(csv_row)

      {
        name: contact.presence || name,
        company: contact.present? ? name : nil,
        email: valid_email(csv_row["email"]),
        phone: squish(csv_row["phone"]) || squish(csv_row["mobile"]),
        address: address_for(csv_row),
        external_source: "wave",
        external_ref: name.downcase
      }
    end

    # Wave models a business ("Lightzone") with a separate contact person
    # ("Dalal Bazzoun"). SmartPay's Client has one name plus a company, so the
    # person becomes the name and the business becomes the company. Where no
    # contact exists the business name is used on its own.
    def contact_name(csv_row)
      [ squish(csv_row["contact_first_name"]), squish(csv_row["contact_last_name"]) ].compact_blank.join(" ")
    end

    def address_for(csv_row)
      [
        squish(csv_row["address_line_1"]),
        squish(csv_row["address_line_2"]),
        [ squish(csv_row["city"]), squish(csv_row["province/state"]) ].compact_blank.join(", ").presence,
        squish(csv_row["postal_code/zip_code"]),
        squish(csv_row["country"])
      ].compact_blank.join("\n").presence
    end

    def valid_email(raw)
      value = squish(raw)&.downcase
      return nil if value.blank?
      value.match?(URI::MailTo::EMAIL_REGEXP) ? value : nil
    end

    def dropped_email?(csv_row)
      squish(csv_row["email"]).present? && valid_email(csv_row["email"]).nil?
    end

    # Later rows fill gaps left by earlier ones — a duplicate that carries a
    # phone number the first row lacked is worth keeping.
    def merge_into(row, attributes)
      return if row.nil?
      attributes.each { |key, value| row.attributes[key] = value if row.attributes[key].blank? && value.present? }
    end

    def squish(value)
      value&.to_s&.squish.presence
    end
  end
end
