class Product < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:name) }

  def to_line_item
    { description: name, quantity: 1, unit_price: unit_price }
  end
end
