class Avo::Resources::Invoice < Avo::BaseResource
  self.icon = "tabler/outline/file-invoice"
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
    field :client_id, as: :number
    field :invoice_number, as: :text
    field :status, as: :select, enum: ::Invoice.statuses
    field :issue_date, as: :date
    field :due_date, as: :date
    field :subtotal, as: :number
    field :tax_rate, as: :number
    field :tax_amount, as: :number
    field :total_amount, as: :number
    field :notes, as: :textarea
    field :paid_date, as: :date_time
    field :payment_method, as: :text
    field :public_token, as: :text
    field :uuid, as: :text
    field :account, as: :belongs_to
    field :client, as: :belongs_to
    field :invoice_items, as: :has_many
    field :payments, as: :has_many
  end
end
