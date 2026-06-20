set :rails_env, "production"

server "your-server-ip", user: "deploy", roles: %w{app db web}

set :ssh_options, {
  keys: %w(~/.ssh/id_rsa),
  forward_agent: true,
  auth_methods: %w(publickey)
}
