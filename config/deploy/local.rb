server 'core-01',
  user: 'core',
  roles: %w{web},
  ssh_options: {
    user: 'user_name', # overrides user setting above
    keys: %w(~/.vagrant.d/insecure_private_key),
    forward_agent: false,
    auth_methods: %w(publickey)
  }

set :deploy_to, '/opt/src'
set :repo_url, 'https://github.com/mookjp/rails-docker-example.git'
