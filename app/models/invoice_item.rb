class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  # Negative prices are allowed so a discount can be expressed as its own
  # line, which is how invoices are conventionally written and how imported
  # ledgers record them.
  validates :unit_price, presence: true, numericality: true

  before_save :calculate_amount

  private

  def calculate_amount
    self.amount = (quantity || 0) * (unit_price || 0)
  end
end
