class AddDetailsToLineItems < ActiveRecord::Migration[8.1]
  # An optional longer description shown beneath the line's title, mirroring a
  # product's own description. The existing `description` column stays the
  # line's title/name.
  def change
    add_column :invoice_items, :details, :text
    add_column :recurring_invoice_items, :details, :text
  end
end
