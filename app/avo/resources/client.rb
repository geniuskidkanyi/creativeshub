class Avo::Resources::Client < Avo::BaseResource
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
    field :name, as: :text
    field :email, as: :text
    field :phone, as: :text
    field :company, as: :text
    field :address, as: :textarea
    field :account, as: :belongs_to
    field :invoices, as: :has_many
  end
end
