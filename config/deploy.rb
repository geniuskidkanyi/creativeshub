lock "~> 3.20.1"

set :application, "creativeshub"
set :repo_url, "git@github.com:your-username/creativeshub.git"

set :branch, :main

set :deploy_to, "/var/www/creativeshub"

set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip
set :rbenv_map_bins, %w{rake gem bundle ruby rails}

append :linked_files, "config/master.key", "config/database.yml"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "storage"

set :keep_releases, 5

set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"

set :default_env, {
  "RAILS_MASTER_KEY" => ENV["RAILS_MASTER_KEY"]
}
