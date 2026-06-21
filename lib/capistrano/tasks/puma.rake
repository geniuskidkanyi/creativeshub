namespace :puma do
  desc "Start Puma"
  task :start do
    on roles(:app) do
      within current_path do
        execute "cd #{current_path} && RAILS_ENV=production bundle exec puma -C config/puma.rb -b #{fetch(:puma_bind)} --daemon"
      end
    end
  end

  desc "Stop Puma"
  task :stop do
    on roles(:app) do
      within current_path do
        if test("[ -f #{fetch(:puma_pid)} ]")
          execute "cd #{current_path} && RAILS_ENV=production bundle exec pumactl -P #{fetch(:puma_pid)} stop"
        end
      end
    end
  end

  desc "Restart Puma"
  task :restart do
    on roles(:app) do
      within current_path do
        if test("[ -f #{fetch(:puma_pid)} ]") && test("kill -0 $(cat #{fetch(:puma_pid)}) 2>/dev/null")
          execute "cd #{current_path} && RAILS_ENV=production bundle exec pumactl -P #{fetch(:puma_pid)} restart"
        else
          execute "cd #{current_path} && RAILS_ENV=production bundle exec puma -C config/puma.rb -b #{fetch(:puma_bind)} --daemon"
        end
      end
    end
  end

  desc "Puma status"
  task :status do
    on roles(:app) do
      within current_path do
        if test("[ -f #{fetch(:puma_pid)} ]")
          execute "cd #{current_path} && bundle exec pumactl -P #{fetch(:puma_pid)} status"
        else
          info "Puma not running"
        end
      end
    end
  end
end

after "deploy:published", "puma:restart"
