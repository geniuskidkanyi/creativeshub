class Avo::Resources::Payment < Avo::BaseResource
  self.icon = "tabler/outline/cash"
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
    field :invoice_id, as: :number
    field :waychit_id, as: :text
    field :status, as: :select, enum: ::Payment.statuses
    field :amount, as: :number
    field :currency, as: :text
    field :payment_method, as: :select, enum: ::Payment.payment_methods
    field :client_reference, as: :text
    field :transaction_reference, as: :text
    field :metadata, as: :code
    field :paid_at, as: :date_time
    field :webhook_data, as: :code
    field :account_id, as: :number
    field :note, as: :text
    field :invoice, as: :belongs_to
    field :account, as: :belongs_to
  end
end
