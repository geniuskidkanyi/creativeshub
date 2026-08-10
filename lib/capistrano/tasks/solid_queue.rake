# Manages the SolidQueue worker (bin/jobs) as a systemd *user* service
# (~/.config/systemd/user/smartpay-jobs.service on the deploy user), restarting
# it on each deploy so it picks up new code.
#
# Without a running worker, ActiveJob just enqueues into SolidQueue and nothing
# ever runs: imports never preview, emails never send, recurring invoices never
# generate.
#
# Uses `systemctl --user` (no sudo). Over a non-login SSH session the user bus
# isn't wired up automatically, so XDG_RUNTIME_DIR must point at the user's
# runtime dir — which exists because linger is enabled
# (`sudo loginctl enable-linger deploy`, done once during setup).
namespace :solid_queue do
  %i[start stop restart status].each do |action|
    desc "#{action.to_s.capitalize} the SolidQueue worker (systemd --user)"
    task action do
      on roles(:app) do
        uid = capture(:id, "-u").strip
        with xdg_runtime_dir: "/run/user/#{uid}" do
          execute :systemctl, "--user", action.to_s, "smartpay-jobs"
        end
      end
    end
  end
end

# Pick up new code on every deploy, exactly like puma:restart.
after "deploy:finished", "solid_queue:restart"
