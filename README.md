rails-dokcer-example
================================================================================

This repository is a example project by Rails with Resque worker.
The structure of the project is following; quite simple:

```
                 ███████████████████         ███████████████████  
                 ███████████████████         ███████████████████  
                 ███████Redis███████         ██████Postgre██████  
                 ███████████████████         ███████████████████  
                 ███████████████████         ███████████████████  
                       ┼  ▲                           ▲
                       │  │                           │
     Load    ┌─────────┘  │                           │
 information │            │                ┌─────────────────────┐
   for job   │            │                │        Rails        │
            ╱│╲           │                │   Web application   │
    ┌─────────────────┐   │                │                     │
    │                 │   │                │   ┌──────────────┐  │
    │  Rescue worker  │   │ Register jobs  │   │              │  │
    │                 │   └────────────────┼───│ Resque Task  │  │
    │                 │                    │   │              │  │
    └─────────────────┘                    │   └──────────────┘  │
                                           └─────────────────────┘
```

* Rails
* Resque
    * It can be used by Rails and also worker is run independently
    * It is expected to be run as several workers
* Postgre
    * DB for models of Rails
* Redis
    * For Resque

## How to run containers

### Requirements

These are required to run it as Docker containers.

* docker
* docker-compose

### Run containers

All you have to do is bellow:

```sh
docker-compose up
```

## For development environment

## Deployment

This is example to deploy these containers to a Ubuntu droplet on
[DigitalOcean](https://www.digitalocean.com/).

### Set up for DigitalOcean droplet

#### Install Docker and Docker Compose

Install the latest Docker by following documentation: [Ubuntu - Docker
Documentation](https://docs.docker.com/installation/ubuntulinux/#docker-maintained-package-installation)

```sh
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.com/ubuntu docker main \
apt/sources.list.d/docker.list"
sudo apt-get update && \
    apt-get install -y lxc-docker
```

Install Docker Compose

```sh
curl -L https://github.com/docker/compose/releases/download/1.1.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod a+x /usr/local/bin/docker-compose
```

#### Set up deploy user

It needs that `deploy` user to deploy source code to this droplet.

```sh
sudo adduser deploy
sudo passwd -l deploy # Do this to make password string which is not able to input
```

Add deploy user to `docker` group to be able to execute `docker` command.

```sh
sudo gpasswd -a deploy docker
```

And create key for deploy user.

```sh
su deploy
ssh-keygen -t rsa -C "deploy"
```

#### Add deploy keys to repo on Github

Create deploy key of your repository with key of deploy user: [Managing deploy keys | GitHub API](https://developer.github.com/guides/managing-deploy-keys/#setup-2)

After set up deploy key of your repository, you can clone your repository via git command like this:

```sh
git clone git@github.com:your-username/your-repo.git
```

### capistrano

To deploy the application to droplet, it has capistrano file.

### Deploy with CircleCI

#### circle.yml

This project has a sample `circle.yml` to deploy it to DO's droplet.
