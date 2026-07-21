module WaveImporter
  # Writes parsed Wave data into the account.
  #
  # Deliberately does NOT create Payment records for invoices Wave shows as
  # paid. Payments are what SmartPay actually collected through Modem Pay and
  # they drive Account#available_payout_balance — inventing them from imported
  # history would credit the business with a balance it can withdraw but never
  # received. Paid invoices carry status and paid_date only.
  class Committer
    Result = Struct.new(:clients_created, :clients_updated, :invoices_created, :invoices_skipped,
                        :products_created, :items_created, :errors, keyword_init: true)

    def initialize(account, kind:, path:)
      @account = account
      @kind = kind
      @path = path
      @result = Result.new(clients_created: 0, clients_updated: 0, invoices_created: 0,
                           invoices_skipped: 0, products_created: 0, items_created: 0, errors: [])
    end

    def call
      case @kind
      when "customers" then import_customers
      when "accounting" then import_accounting
      else @result.errors << "Unsupported file type: #{@kind}"
      end
      @result
    end

    private

    def import_customers
      CustomersParser.new(@path).call.each do |row|
        client = find_or_initialize_client(row.attributes[:external_ref])
        was_new = client.new_record?
        client.assign_attributes(row.attributes)

        if client.save
          was_new ? @result.clients_created += 1 : @result.clients_updated += 1
        else
          @result.errors << "Line #{row.line} (#{row.attributes[:name]}): #{client.errors.full_messages.join(', ')}"
        end
      end
    end

    def import_accounting
      parsed = AccountingParser.new(@path).call
      import_products(parsed[:products])

      parsed[:invoices].each do |parsed_invoice|
        import_invoice(parsed_invoice)
      rescue ActiveRecord::RecordInvalid => e
        @result.errors << "Invoice #{parsed_invoice.external_ref}: #{e.record.errors.full_messages.join(', ')}"
      end
    end

    def import_invoice(parsed_invoice)
      # Re-running an import must not duplicate: external_ref is uniquely
      # indexed per account.
      if @account.invoices.exists?(external_source: "wave", external_ref: parsed_invoice.external_ref)
        @result.invoices_skipped += 1
        return
      end

      client = client_for(parsed_invoice)

      invoice = @account.invoices.new(
        client: client,
        invoice_number: parsed_invoice.external_ref,
        issue_date: parsed_invoice.issue_date,
        status: parsed_invoice.status,
        paid_date: parsed_invoice.paid_date,
        tax_rate: parsed_invoice.tax_rate,
        notes: notes_for(parsed_invoice),
        external_source: "wave",
        external_ref: parsed_invoice.external_ref
      )

      parsed_invoice.items.each do |item|
        invoice.invoice_items.new(description: item[:description], quantity: item[:quantity], unit_price: item[:unit_price])
      end

      invoice.save!
      @result.invoices_created += 1
      @result.items_created += parsed_invoice.items.size
    end

    # Invoices reference a customer by name. When the customers export has not
    # been imported (or the ledger names someone who was never in it) the
    # client is created on the spot so no invoice is dropped.
    def client_for(parsed_invoice)
      ref = parsed_invoice.customer_ref.presence || "unknown"

      client = find_or_initialize_client(ref)
      if client.new_record?
        client.assign_attributes(
          name: parsed_invoice.customer_name.presence || "Unknown customer",
          external_source: "wave",
          external_ref: ref
        )
        client.save!
        @result.clients_created += 1
      end
      client
    end

    def find_or_initialize_client(ref)
      @account.clients.find_or_initialize_by(external_source: "wave", external_ref: ref)
    end

    def import_products(products)
      products.each do |attributes|
        next if @account.products.exists?(name: attributes[:name])

        product = @account.products.new(name: attributes[:name], unit_price: attributes[:unit_price])
        if product.save
          @result.products_created += 1
        else
          @result.errors << "Product #{attributes[:name]}: #{product.errors.full_messages.join(', ')}"
        end
      end
    end

    def notes_for(parsed_invoice)
      parsed_invoice.warnings.presence&.join("\n")
    end
  end
end
