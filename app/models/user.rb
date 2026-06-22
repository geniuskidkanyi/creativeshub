class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  belongs_to :account, optional: true

  enum :role, { owner: "owner", admin: "admin", member: "member" }

  validates :name, presence: true
  validates :role, presence: true

  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role ||= (account.present? && account.users.none?) ? :owner : :member
  end
end
