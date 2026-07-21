class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :account

  pg_search_scope :search_all,
                  against: [ :name, :description ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.3, word_similarity: true }
                  }

  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:name) }

  def to_line_item
    { description: name, quantity: 1, unit_price: unit_price }
  end
end
