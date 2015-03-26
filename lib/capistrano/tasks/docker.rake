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
      invoke "docker:run_shared_containers"
      invoke "docker:run_app_containers"
      invoke "docker:register_new_server"
    end
  end

  desc 'Run shared containers; postgres, redis and data-container'
  task :run_shared_containers do
    on roles(:all) do |host|
      # TODO: Add conditions whether run containers or not; check container is running or not
      execute "/opt/bin/docker-compose -p #{fetch(:project)} -f #{fetch(:compose_file_path)} up -d"
    end
  end

  desc 'Build and run web and resque containers'
  task :run_app_containers do
    on roles(:all) do |host|
      # Run docker container named like railsdockerexample_web_428ba3
      execute "docker run -d \
        --name #{fetch(:project)}_web_`git -C #{fetch(:repo_path)} rev-parse #{fetch(:branch)}` \
        --link #{fetch(:project)}_postgres_1:postgres \
        --link #{fetch(:project)}_redis_1:redis \
        -P \
        #{fetch(:branch)}"
      # Run docker container named like railsdockerexample_resque_428ba3
      execute "docker run -d \
        --name #{fetch(:project)}_resque_`git -C #{fetch(:repo_path)} rev-parse #{fetch(:branch)}` \
        --link #{fetch(:project)}_redis_1:redis \
        --volumes-from #{fetch(:project)}_data_1 \
        --env 'QUEUE=*' \
        #{fetch(:branch)} rake environment resque:work"
    end
  end

  desc 'Register the latest container as Server to be handled by vulcand'
  task :register_new_server do
    on roles(:all) do |host|
      commit_id = capture("git -C #{fetch(:repo_path)} rev-parse origin/master")
      info "commit id is #{commit_id}"

      # Get address of new container like "0.0.0.0:49154"
      inspected_address = capture("docker port #{fetch(:project)}_web_`git -C #{fetch(:repo_path)} rev-parse origin/master`").split('->').last.strip.chomp
      info "address is #{inspected_address}"

      # Register address of container as Server
      execute "etcdctl set /vulcand/backends/#{commit_id}/backend '{\"Type\": \"http\"}'"
      # TODO: Get containers shared network address or get address dynamically
      execute "etcdctl set /vulcand/backends/#{commit_id}/servers/srv1 '{\"URL\": \"http://10.1.42.1:#{inspected_address.split(':').last}\"}'"

      # Get HTTP status code of container and wait until the container is ready
      while capture("curl -LI http://#{inspected_address} -o /dev/null -w '%{http_code}' -s | cat") == '000'
        info 'status code is 000. the container is not ready and continue to retry....'
        sleep 1
      end

      # Register new container to Frontend
      execute "etcdctl set /vulcand/frontends/f1/frontend '{\"Type\": \"http\", \"BackendId\":\"#{commit_id}\",\"Route\": \"PathRegexp(`/.*`)\"}'"
    end
  end

  before :deploy, :update
  before :deploy, :build
end
