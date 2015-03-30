# -*- mode: ruby -*-
# # vi: set ft=ruby :

SYNCED_DIR_PATH = '/home/deploy/rails-docker-example'

# provisioning script
# TODO: split it as .sh file
$script = <<SCRIPT
# Install Docker
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.com/ubuntu docker main\
> /etc/apt/sources.list.d/docker.list"
sudo apt-get update && \
    sudo apt-get install -y --force-yes lxc-docker

# Install Docker compose
sudo curl -L https://github.com/docker/compose/releases/download/1.1.0/docker-compose-`uname -s`-`uname -m` > ~/docker-compose
sudo cp ~/docker-compose /usr/local/bin/docker-compose
sudo chmod a+x /usr/local/bin/docker-compose

# Setup deploy user
sudo adduser --gecos "" --disabled-password deploy
sudo passwd -l deploy # Do this to make password string which is not able to input
sudo gpasswd -a deploy docker
su deploy
mkdir -p /home/deploy/.ssh/
cp /home/vagrant/.ssh/authorized_keys /home/deploy/.ssh/

# Add cron script to create backup for data-only-container
sudo cp #{SYNCED_DIR_PATH}/provisioning/backup-data-container.sh /etc/cron.hourly/

# Create source dir
sudo mkdir -p /opt/src
sudo chown deploy:deploy /opt/src

# Create swapfile
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Create backup dir
# Backup directory for /tmp items in Resque container
sudo mkdir -p /backup/tmp
# Backup directory for postgres data
sudo mkdir -p /backup/db

# Run etcd
docker run -d --name etcd -p 4441:4001 -p 7771:7001 microbox/etcd:0.4.6 etcd
# Run vulcand
# TODO: Get address of host gateway dinamically
docker run -d --name vulcand -p 80:8181 -p 8182:8182 mailgun/vulcand:v0.8.0-beta.2 /go/bin/vulcand -apiInterface=0.0.0.0 --etcd=http://172.17.42.1:4441
# Run this only local environment
docker-compose -p rails-docker-example -f #{SYNCED_DIR_PATH}/docker-compose.yml up -d
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.define vm_name = "ubuntu" do |config|
    config.vm.hostname = vm_name
    config.vm.box = "ubuntu14.10_amd64" #TODO: Add amd64 to the name
    config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/utopic/current/utopic-server-cloudimg-amd64-vagrant-disk1.box"

    config.vm.provision "shell", inline: $script
    config.vm.synced_folder ".", SYNCED_DIR_PATH
    config.vm.network "private_network", ip: "192.168.100.100"
    config.ssh.insert_key = false
  end
end
