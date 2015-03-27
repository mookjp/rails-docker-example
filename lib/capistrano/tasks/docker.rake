require 'json'

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
      invoke "docker:run_app_containers"
      invoke "docker:register_new_server"
    end
  end

  desc 'Run shared containers: postgres, redis and data-container; this should be run if shared container is not running'
  task :run_shared_containers do
    on roles(:all) do |host|
      invoke "docker:update"
      execute "/opt/bin/docker-compose -p #{fetch(:project)} -f #{fetch(:compose_file_path)} up -d"
    end
  end

  desc 'Build and run web and resque containers'
  task :run_app_containers do
    on roles(:all) do |host|
      git_commit_id = capture("git -C #{fetch(:repo_path)} rev-parse #{fetch(:branch)}").chomp

      # Run container only if it does not exists
      # If the specified container doesn't exists, `docker inspect` exit with error code
      web_container_name = "#{fetch(:project)}_web_#{git_commit_id}"
      begin
        execute "docker inspect #{web_container_name}"
        info "`#{web_container_name}` exists."
      rescue
        info "run `#{web_container_name}` ..."
        # Run docker container named like railsdockerexample_web_428ba3
        execute "docker run -d \
            --name #{web_container_name} \
            --link #{fetch(:project)}_postgres_1:postgres \
            --link #{fetch(:project)}_redis_1:redis \
            -P \
                #{fetch(:branch)}"
      end

      # Run container only if it does not exists
      # If the specified container doesn't exists, `docker inspect` exit with error code
      resque_container_name = "#{fetch(:project)}_resque_#{git_commit_id}"
      begin
        execute "docker inspect #{resque_container_name}"
        info "`#{resque_container_name}` exists."
      rescue
        info "run `#{resque_container_name}` ..."
        # Run docker container named like railsdockerexample_resque_428ba3
        execute "docker run -d \
        --name #{resque_container_name} \
        --link #{fetch(:project)}_redis_1:redis \
        --volumes-from #{fetch(:project)}_data_1 \
        --env 'QUEUE=*' \
                #{fetch(:branch)} rake environment resque:work"
      end
    end
  end

  desc 'Register the latest container as Server to be handled by vulcand'
  task :register_new_server do
    on roles(:all) do |host|
      commit_hash = capture("git -C #{fetch(:repo_path)} rev-parse origin/master")
      info "new containers' commit hash is #{commit_hash}"

      # Get address of new container like "0.0.0.0:49154"
      inspected_address = capture("docker port #{fetch(:project)}_web_#{commit_hash}").split('->').last.strip.chomp
      info "address is #{inspected_address}"

      # Register address of container as Server
      execute "etcdctl set /vulcand/backends/#{commit_hash}/backend '{\"Type\": \"http\"}'"
      # TODO: Get containers shared network address or get address dynamically
      execute "etcdctl set /vulcand/backends/#{commit_hash}/servers/srv1 '{\"URL\": \"http://10.1.42.1:#{inspected_address.split(':').last}\"}'"

      # Get HTTP status code of container and wait until the container is ready
      while capture("curl -LI http://#{inspected_address} -o /dev/null -w '%{http_code}' -s | cat") == '000'
        info 'status code is 000. the container is not ready and continue to retry....'
        sleep 1
      end

      # Get old containers' commit hash
      old_commit_hash = nil
      begin
        old_commit_hash = JSON(capture("etcdctl get /vulcand/frontends/f1/frontend"))['BackendId']
        info "old containers' commit hash is #{old_commit_hash}"
      rescue
        info "there's no old containers."
      end

      # Register new container to Frontend
      execute "etcdctl set /vulcand/frontends/f1/frontend '{\"Type\": \"http\", \"BackendId\":\"#{commit_hash}\",\"Route\": \"PathRegexp(`/.*`)\"}'"

      # Remove old containers if it exists
      if old_commit_hash != nil
        execute "docker rm -f #{fetch(:project)}_web_#{old_commit_hash}"
        execute "docker rm -f #{fetch(:project)}_resque_#{old_commit_hash}"
      end
    end
  end
end
