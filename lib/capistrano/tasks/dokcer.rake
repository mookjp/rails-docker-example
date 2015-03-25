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
      execute "cd #{fetch(:repo_path)} && \
                docker build -t `git rev-parse #{fetch(:branch)}` ."
    end
  end

  desc 'Up containers'
  task :deploy do
    on roles(:all) do |host|
      invoke "docker:update"
      invoke "docker:build"
      invoke "docker:create_containers"
      invoke "docker:run_shared_containers"
      invoke "docker:run_app_containers"
    end
  end

  desc "Create containers"
  task :create_containers do
    on roles(:all) do |host|
      execute "docker create --name data \
                -v /tmp -v /var/lib/postgresql/data busybox"
      execute "docker create --name postgres \
        --env 'POSTGRES_USER=postgres' \
        --env 'POSTGRES_PASSWORD=password' \
        --volumes-from data \
        postgres"
      execute 'docker create --name redis redis'
    end
  end

  desc 'Run shared containers; postgres, redis and data-container'
  task :run_shared_containers do
    on roles(:all) do |host|
      execute 'docker start data'
      execute 'docker start postgres'
      execute 'docker start redis'
    end
  end

  desc 'Build and run web and resque containers'
  task :run_app_containers do
    on roles(:all) do |host|
      execute "docker run --name web_`git rev-parse #{fetch(:branch)}` \
                --link postgres:postgres \
                --link redis:redis \
                -P \
                #{fetch(:branch)}"
      execute "docker run --name resque_`git rev-parse #{fetch(:branch)}` \
                --link redis:redis \
                --volumes-from data \
                --env 'QUEUE=*' \
                #{fetch(:branch)} rake environment resque:work"
    end
  end

  desc 'Restart all containers'
  task :restart do
    execute "docker rm -f $(docker ps -q)"
    execute "docker run -d --net=host -p 80:80 -p 8181:8181 \
      mailgun/vulcand:v0.8.0-beta.2 \
      /go/bin/vulcand -apiInterface='0.0.0.0' -etcd='http://0.0.0.0:4001' -port=80 -apiPort=8181"
    invoke "docker:run_shared_containers"
    invoke "docker:run_app_containers"
  end

  before :deploy, :update
  before :deploy, :build
end
