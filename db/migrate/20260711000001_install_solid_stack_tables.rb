# Production points the cable/cache/queue databases at the primary
# DATABASE_URL, but their tables live in standalone schema files
# (db/*_schema.rb) that a plain db:migrate — which is what capistrano runs —
# never loads. Load whichever are missing so solid_cable (websockets),
# solid_cache and solid_queue (deliver_later) work on the shared database.
class InstallSolidStackTables < ActiveRecord::Migration[8.1]
  SCHEMAS = {
    "solid_cable_messages" => "cable_schema.rb",
    "solid_cache_entries" => "cache_schema.rb",
    "solid_queue_jobs" => "queue_schema.rb"
  }.freeze

  def up
    SCHEMAS.each do |marker_table, schema_file|
      next if table_exists?(marker_table)

      load Rails.root.join("db", schema_file)
    end

    # Each schema file records its own version (1) into schema_migrations;
    # drop it so it doesn't linger as a phantom migration.
    execute "DELETE FROM schema_migrations WHERE version = '1'"
  end

  def down
    # Intentionally kept: the tables may hold live cable/cache/queue data.
  end
end
