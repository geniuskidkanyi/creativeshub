class EnablePgTrgm < ActiveRecord::Migration[8.1]
  # Trigram matching powers typo-tolerant search (pg_search :trigram) and
  # fast substring matching on identifiers like invoice numbers.
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
  end
end
