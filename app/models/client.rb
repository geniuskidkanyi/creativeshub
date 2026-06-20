class Client < ApplicationRecord
  belongs_to :account
  has_many :invoices, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :ordered, -> { order(created_at: :desc) }
end
