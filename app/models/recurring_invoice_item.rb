class RecurringInvoiceItem < ApplicationRecord
  belongs_to :recurring_invoice

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: true

  def to_invoice_item_attributes
    { description: description, details: details, quantity: quantity, unit_price: unit_price }
  end
end
