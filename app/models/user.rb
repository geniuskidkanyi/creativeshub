class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  belongs_to :account, optional: true

  # In-app notifications (noticed). Each row is one delivered notification.
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"

  enum :role, { owner: "owner", admin: "admin", member: "member" }

  validates :name, presence: true
  validates :role, presence: true

  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role ||= (account.present? && account.users.none?) ? :owner : :member
  end
end
