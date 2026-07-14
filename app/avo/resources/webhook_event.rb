class Avo::Resources::WebhookEvent < Avo::BaseResource
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
    field :event_id, as: :text
    field :event_type, as: :text
    field :payload, as: :code
    field :processed_at, as: :date_time
    field :status, as: :select, enum: ::WebhookEvent.statuses
  end
end
