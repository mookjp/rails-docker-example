mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/

# Create source dir
sudo mkdir -p /opt/src
sudo chown core:core /opt/src

# Install docker compose
curl -L https://github.com/docker/compose/releases/download/1.1.0/docker-compose-`uname -s`-`uname -m` > ~/docker-compose
sudo mkdir -p /opt/bin
sudo mv ~/docker-compose /opt/bin/docker-compose
sudo chown root:root /opt/bin/docker-compose
sudo chmod +x /opt/bin/docker-compose

# Run vulcand
docker run -d --name vulcand -p 80:8181 -p 8182:8182 mailgun/vulcand:v0.8.0-beta.2 /go/bin/vulcand -apiInterface=0.0.0.0 --etcd=http://10.1.42.1:4001
# Run this only local environment
docker-compose -p rails-docker-example -f "#{SYNCED_DIR_PATH}"/docker-compose.yml up -d
echo "The environment is ready! Please deploy your code with `bundle exec cap local docker:deploy` from your machine."
