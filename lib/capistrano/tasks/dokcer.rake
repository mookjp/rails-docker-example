namespace :docker do
  desc 'Update repo and reset to :branch'
  task :update do
    on roles(:all) do |host|
      if test("[ -d #{fetch(:repo_path)} ]")
        info 'found!'
        execute "git -C #{fetch(:repo_path)} fetch origin"
        execute "git -C #{fetch(:repo_path)} reset --hard #{fetch(:branch)}"
      else
        info 'not found'
        execute "git clone #{fetch(:repo_url)} #{fetch(:deploy_to)}/#{fetch(:application)}"
        execute "git -C #{fetch(:repo_path)} reset --hard #{fetch(:branch)}"
      end
    end
  end

  desc 'Build image'
  task :build do
    on roles(:all) do |host|
      execute "cd #{fetch(:repo_path)}; docker-compose -f #{File.join(fetch(:repo_path), 'docker-compose.yml')} build"
    end
  end

  desc 'Up containers'
  task :deploy do
    on roles(:all) do |host|
      execute "cd #{fetch(:repo_path)}; docker-compose -f #{File.join(fetch(:repo_path), 'docker-compose.yml')} stop"
      execute "cd #{fetch(:repo_path)}; docker-compose -f #{File.join(fetch(:repo_path), 'docker-compose.yml')} rm --force"
      execute "cd #{fetch(:repo_path)}; docker-compose -f #{File.join(fetch(:repo_path), 'docker-compose.yml')} up -d"
    end
  end

  before :deploy, :update
  before :deploy, :build
end
