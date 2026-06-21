lock "~> 3.20"

set :application, "smartpay"
set :repo_url, "git@github.com:geniuskidkanyi/creativeshub.git"
set :branch, ENV.fetch("BRANCH", "modem-pay")

set :deploy_to, "/home/deploy/smartpay"

set :format, :airbrussh
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

set :pty, true
set :keep_releases, 5

append :linked_files, "config/master.key", "config/database.yml", ".env"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", ".bundle", "storage"

set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip

set :puma_preload_app, true
set :puma_prune_bundler, true
set :puma_workers, 2
set :puma_threads, [0, 16]
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{shared_path}/log/puma.access.log"
set :puma_error_log, "#{shared_path}/log/puma.error.log"

# Rails
set :rails_env, :production
set :migration_role, :app
set :assets_roles, [:app]