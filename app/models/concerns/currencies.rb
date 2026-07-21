# Shared currency reference for anything money-denominated. Invoices and
# recurring schedules are issued in one of these; a business's payout balance
# is always GMD, so a non-GMD invoice carries an fx_rate to convert back.
module Currencies
  extend ActiveSupport::Concern

  # code => [ symbol, name ]. Order controls how the picker lists them.
  CURRENCIES = {
    "GMD" => [ "D", "Gambian Dalasi" ],
    "USD" => [ "$", "US Dollar" ],
    "EUR" => [ "€", "Euro" ],
    "GBP" => [ "£", "British Pound" ],
    "CAD" => [ "C$", "Canadian Dollar" ],
    "XOF" => [ "CFA", "West African CFA Franc" ],
    "NGN" => [ "₦", "Nigerian Naira" ],
    "GHS" => [ "₵", "Ghanaian Cedi" ],
    "AED" => [ "د.إ", "UAE Dirham" ],
    "CNY" => [ "¥", "Chinese Yuan" ]
  }.freeze

  BASE_CURRENCY = "GMD".freeze

  class_methods do
    def currency_options
      CURRENCIES.map { |code, (symbol, name)| [ "#{code} (#{symbol}) — #{name}", code ] }
    end
  end

  def currency_symbol
    CURRENCIES.dig(currency, 0) || currency
  end

  def base_currency? = currency == BASE_CURRENCY

  # amount rendered with this record's currency symbol, e.g. "$500.00".
  def format_money(amount, precision: 2)
    formatted = ActiveSupport::NumberHelper.number_to_rounded(amount.to_f, precision: precision, delimiter: ",")
    "#{currency_symbol}#{formatted}"
  end
end
