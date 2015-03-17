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

For development environment, it uses a container for redis only.
You can use `rails cosnole` and `SQLite` on your local machine.

If you use MacOSX, install needed packages by `brew`:

```sh
brew update
brew install boot2docker docker docker-compose
```

Then run redis container and Rails server:

```sh
docker-compose run redis
bundle exec rails s
```

## Deployment

This is example to deploy these containers to a Ubuntu 14.04 droplet on
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

To deploy the application to droplet, it has capistrano file. Execute deployment manually by executing this command:

```sh
DEPLOY_TARGET_HOST=your.host.name bundle exec cap staging docker:deploy
```

`docker.rake` has 3 tasks.

1. update
  * Update git repository of Rails project
2. build
  * Build Docker images
3. deploy
  * Run Docker containers

Building images and runnnig containers works by execute `docker-compose`.
See [docker-compose.yml](https://github.com/mookjp/rails-docker-example/blob/master/docker-compose.yml)

#### * If you met `exit status 4` while building Docker image

You may meet this error while you build your Docker image:

```
Your compiler failed with the exit status 4. This probably means that it ran out of memory. To solve this problem, try increasing your swap space: https://www.digitalocean.com/community/articles/how-to-add-swap-on-ubuntu-12-04
```

You can upgrade space to add swap space following this procedure:
[How To Add Swap on Ubuntu 14.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04)

I confirmed that swap 4GB works for this project.

### Deploy with CircleCI

#### circle.yml

This project has a sample `circle.yml` to deploy it to DO's droplet.
