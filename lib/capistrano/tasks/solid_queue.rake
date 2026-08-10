# Manages the SolidQueue worker (bin/jobs) via systemd, mirroring the puma
# tasks in config/deploy.rb. Requires a `smartpay-jobs` systemd unit on the
# server and passwordless sudo for `systemctl {start,stop,restart}
# smartpay-jobs` by the deploy user (same as smartpay-puma).
#
# Without a running worker, ActiveJob just enqueues into SolidQueue and nothing
# ever runs: imports never preview, emails never send, recurring invoices never
# generate. This keeps the worker alive and picking up new code on each deploy.
namespace :solid_queue do
  # sudo -n: never prompt — fail loudly if passwordless sudo isn't set up
  # rather than hanging the deploy on an invisible password prompt.
  desc "Start the SolidQueue worker via systemd"
  task :start do
    on roles(:app) do
      execute :sudo, "-n", :systemctl, :start, "smartpay-jobs"
    end
  end

  desc "Stop the SolidQueue worker via systemd"
  task :stop do
    on roles(:app) do
      execute :sudo, "-n", :systemctl, :stop, "smartpay-jobs"
    end
  end

  desc "Restart the SolidQueue worker via systemd"
  task :restart do
    on roles(:app) do
      execute :sudo, "-n", :systemctl, :restart, "smartpay-jobs"
    end
  end
end

# Pick up new code on every deploy, exactly like puma:restart.
after "deploy:finished", "solid_queue:restart"
