module WaveImporter
  # Reconstructs invoices, line items and a product catalogue from Wave's
  # general-ledger export.
  #
  # accounting.csv is double-entry bookkeeping, not an invoice list, so each
  # invoice has to be reassembled from the rows that reference it:
  #
  #   Income rows (credit)                -> line items, one per row
  #   System Receivable Invoice (debit)   -> the invoice itself: date + total
  #   System Receivable Invoice (credit)  -> a payment against that invoice
  #
  # Line descriptions are written by Wave as "Customer - #Number - Item", so
  # the item text is recovered by stripping that prefix. Verified against the
  # source export: 734 of 734 income rows follow the pattern.
  class AccountingParser
    AR_TYPE = "System Receivable Invoice".freeze
    INCOME_TYPES = [ "Income", "Other Income", "Uncategorized Income" ].freeze
    DISCOUNT_TYPE = "Discount".freeze

    Invoice = Struct.new(:external_ref, :customer_ref, :customer_name, :issue_date, :paid_date,
                         :status, :total, :amount_paid, :tax_amount, :tax_rate, :discount, :items, :warnings, keyword_init: true)

    def initialize(path)
      @path = path
    end

    def call
      rows = read_rows
      grouped = rows.select { |r| ref(r).present? }.group_by { |r| ref(r) }

      invoices = grouped.filter_map { |number, group| build_invoice(number, group) }
      { invoices: invoices, products: derive_products(invoices) }
    end

    private

    def read_rows
      CSV.read(@path, headers: true, encoding: FileDetector::ENCODING)
    end

    def build_invoice(number, group)
      ar_rows = group.select { |r| r["Account Type"] == AR_TYPE }
      issued = ar_rows.find { |r| debit(r) > 0 }

      # Without the A/R debit there is no invoice to build — these are stray
      # ledger lines (a payment recorded against an invoice raised before the
      # export window started).
      return nil if issued.nil?

      customer = squish(issued["Customer"]) || squish(group.first["Customer"])
      items = build_items(group, number, customer)

      total = debit(issued)
      paid = ar_rows.sum { |r| credit(r) }
      tax = group.sum { |r| decimal(r["Sales Tax Amount"]) }
      discount = group.select { |r| r["Account Type"] == DISCOUNT_TYPE }.sum { |r| debit(r) }

      # Wave books a discount as its own ledger entry rather than adjusting
      # the income lines, so without this the invoice would import at its
      # pre-discount value — i.e. for more than the customer actually owed.
      items << { description: "Discount", quantity: 1, unit_price: -discount.round(2) } if discount > 0

      warnings = []
      warnings << "No line items in the ledger — a single summary line was created" if items.empty?
      warnings << "Partially paid in Wave: D#{paid.round(2)} of D#{total.round(2)}. Imported as unpaid — record the balance manually." if paid > 0 && paid < total - 0.01
      warnings << "No customer on the ledger entry" if customer.blank?

      items_total = items.sum { |i| i[:unit_price].to_f }

      # Invoice#calculate_totals derives tax from a percentage rate, while the
      # ledger only records the tax amount — so recover the rate the amount
      # implies, otherwise the tax silently vanishes from the total.
      tax_rate = items_total.zero? ? 0 : (tax / items_total * 100).round(8)

      if items.any? && (items_total + tax - total).abs > 0.01
        warnings << "Line items add up to D#{(items_total + tax).round(2)} but the ledger total is D#{total.round(2)} — check this invoice"
      end

      # A ledger with no line items still has a total, so the invoice is
      # preserved with one line rather than importing an empty document.
      items = [ { description: "Invoice #{number}", quantity: 1, unit_price: total } ] if items.empty?

      Invoice.new(
        external_ref: number,
        customer_ref: customer&.downcase,
        customer_name: customer,
        issue_date: date(issued["Transaction Date"]),
        paid_date: paid > 0 ? date(ar_rows.select { |r| credit(r) > 0 }.map { |r| r["Transaction Date"] }.max) : nil,
        status: status_for(total: total, paid: paid),
        total: total,
        amount_paid: paid,
        tax_amount: tax,
        tax_rate: tax_rate,
        discount: discount,
        items: items,
        warnings: warnings
      )
    end

    def build_items(group, number, customer)
      group.select { |r| INCOME_TYPES.include?(r["Account Type"]) }.map do |row|
        {
          description: strip_prefix(row["Transaction Line Description"], customer, number),
          quantity: 1,
          unit_price: credit(row) - debit(row)
        }
      end
    end

    # "i-Link - #0000118 - Domain Registration" -> "Domain Registration".
    # Falls back to the account name when the prefix is absent so the line
    # never imports blank.
    def strip_prefix(description, customer, number)
      text = squish(description).to_s
      prefix = "#{customer} - #{number} - "
      text = text.delete_prefix(prefix) if text.start_with?(prefix)
      text = text.sub(/\A#{Regexp.escape(number.to_s)}\s*-\s*/, "")
      text.presence || "Item"
    end

    def status_for(total:, paid:)
      return "paid" if paid > 0 && paid >= total - 0.01
      "sent"
    end

    # Every distinct line description becomes a product priced at the value
    # most often invoiced for it — the mode rather than the mean, so one
    # discounted sale does not shift the catalogue price.
    def derive_products(invoices)
      invoices.flat_map(&:items)
              .reject { |i| i[:unit_price].to_f <= 0 }
              .group_by { |i| i[:description] }
              .map do |description, items|
                prices = items.map { |i| i[:unit_price].round(2) }
                {
                  name: description,
                  unit_price: prices.tally.max_by { |_, count| count }.first,
                  times_invoiced: items.size
                }
              end
              .sort_by { |p| -p[:times_invoiced] }
    end

    def ref(row) = squish(row["Invoice Number"])
    def debit(row) = decimal(row["Debit Amount (Two Column Approach)"])
    def credit(row) = decimal(row["Credit Amount (Two Column Approach)"])

    def decimal(value)
      raw = value.to_s.delete(",").strip
      raw.blank? ? 0.0 : raw.to_f
    end

    def date(value)
      Date.parse(value.to_s)
    rescue Date::Error, TypeError
      nil
    end

    def squish(value)
      value&.to_s&.squish.presence
    end
  end
end
