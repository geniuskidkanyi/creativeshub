class Avo::Resources::Payout < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :account_id, as: :number
    field :amount, as: :number
    field :fee, as: :number
    field :currency, as: :text
    field :network, as: :text
    field :account_number, as: :text
    field :beneficiary_name, as: :text
    field :narration, as: :text
    field :status, as: :select, enum: ::Payout.statuses
    field :modempay_transfer_id, as: :text
    field :transfer_reference, as: :text
    field :idempotency_key, as: :text
    field :error_message, as: :textarea
    field :webhook_data, as: :code
    field :account, as: :belongs_to
  end
end
