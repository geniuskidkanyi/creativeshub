class CreateWaveImports < ActiveRecord::Migration[8.1]
  def change
    create_table :wave_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true

      # Which Wave export this file was detected as: customers | accounting.
      t.string :kind
      t.string :status, null: false, default: "pending"
      t.string :original_filename

      # Dry-run output: the parsed rows plus per-row warnings, rendered on the
      # preview screen and re-used verbatim when the import is committed.
      t.jsonb :preview, default: {}, null: false
      t.jsonb :result, default: {}, null: false
      t.text :error_message

      t.datetime :previewed_at
      t.datetime :committed_at

      t.timestamps
    end

    add_index :wave_imports, [ :account_id, :created_at ]
  end
end
