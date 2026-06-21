server "95.216.240.245",
  user: "deploy",
  roles: %w[app db web],
  ssh_options: {
    keys: %w[~/.ssh/id_rsa],
    forward_agent: true,
    auth_methods: %w[publickey]
  }

set :deploy_to, "/home/deploy/smartpay"
set :rails_env, :production
set :branch, ENV.fetch("BRANCH", "modem-pay")
set :puma_workers, 2
