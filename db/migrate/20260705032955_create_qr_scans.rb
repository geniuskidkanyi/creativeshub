class CreateQrScans < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_scans do |t|
      t.timestamps
    end
  end
end
