class Avo::Resources::Product < Avo::BaseResource
  self.icon = "tabler/outline/package"
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
    field :description, as: :textarea
    field :unit_price, as: :number
    field :account, as: :belongs_to
  end
end
