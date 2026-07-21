class Client < ApplicationRecord
  include PgSearch::Model

  belongs_to :account
  has_many :invoices, dependent: :restrict_with_error

  # Word/prefix matching (tsearch) for normal typing, plus trigram so typos
  # and substrings still hit. Always scope to the account before searching.
  pg_search_scope :search_all,
                  against: [ :name, :email, :company, :phone ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.3, word_similarity: true }
                  }

  validates :name, presence: true
  # Email is optional: businesses migrating from other tools routinely have
  # long-standing customers on file with only a phone number or nothing at
  # all. Invoices for those clients are shared by link instead of emailed.
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :emailable, -> { where.not(email: [ nil, "" ]) }

  def emailable?
    email.present?
  end
end
