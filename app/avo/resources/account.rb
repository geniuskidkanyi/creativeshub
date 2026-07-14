class Avo::Resources::Account < Avo::BaseResource
  self.icon = "tabler/outline/user-circle"
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
    field :business_name, as: :text
    field :logo, as: :file
    field :address, as: :textarea
    field :phone, as: :text
    field :website, as: :text
    field :tax_id, as: :text
    field :currency, as: :text
    field :timezone, as: :text
    field :modempay_sub_account_id, as: :text
    field :settlement_code, as: :text
    field :settlement_account_number, as: :text
    field :qr_token, as: :text
    field :qr_secret, as: :text
    field :users, as: :has_many
    field :clients, as: :has_many
    field :invoices, as: :has_many
    field :products, as: :has_many
    field :payouts, as: :has_many
    field :payments, as: :has_many
    field :qr_scans, as: :has_many
  end
end
