class Payout < ApplicationRecord
  belongs_to :account

  NETWORKS = [ [ "Wave", "wave" ], [ "Afrimoney", "afrimoney" ] ].freeze

  enum :status, { pending: "pending", completed: "completed", failed: "failed", flagged: "flagged" }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :network, :account_number, :beneficiary_name, presence: true
  validates :idempotency_key, presence: true, uniqueness: true

  scope :ordered, -> { order(created_at: :desc) }
  # Failed payouts never left the wallet, so they don't count against the balance.
  scope :counted_against_balance, -> { where.not(status: :failed) }

  # Any payout change can move the available balance (new payout, fee set,
  # failed payouts stop counting), so refresh the live balance cards.
  after_commit :broadcast_balance_refresh, on: [ :create, :update ]

  private

  def broadcast_balance_refresh
    account.broadcast_balance_refresh
  end
end
