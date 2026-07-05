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

# Rails
set :rails_env, :production
set :migration_role, :app
set :assets_roles, [:app]

# Puma via systemd
namespace :puma do
  # sudo -n: never prompt — if passwordless sudo isn't set up, fail loudly
  # instead of hanging the deploy on an invisible password prompt.
  desc 'Start puma via systemd'
  task :start do
    on roles(:app) do
      execute :sudo, '-n', :systemctl, :start, 'smartpay-puma'
    end
  end

  desc 'Stop puma via systemd'
  task :stop do
    on roles(:app) do
      execute :sudo, '-n', :systemctl, :stop, 'smartpay-puma'
    end
  end

  desc 'Restart puma via systemd'
  task :restart do
    on roles(:app) do
      execute :sudo, '-n', :systemctl, :restart, 'smartpay-puma'
    end
  end
end

# Automatically restart puma after deploy
after 'deploy:finished', 'puma:restart'