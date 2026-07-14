class Avo::Resources::InvoiceItem < Avo::BaseResource
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
    field :invoice_id, as: :number
    field :description, as: :textarea
    field :quantity, as: :number
    field :unit_price, as: :number
    field :amount, as: :number
    field :invoice, as: :belongs_to
  end
end
