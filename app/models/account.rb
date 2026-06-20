class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy

  validates :business_name, presence: true

  def owner
    users.find_by(role: :owner)
  end
end
