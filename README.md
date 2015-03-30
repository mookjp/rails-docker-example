rails-docker-example
================================================================================

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [Summary](#summary)
- [How to run containers](#how-to-run-containers)
  - [Requirements](#requirements)
  - [Run containers](#run-containers)
- [For development environment](#for-development-environment)
- [Deployment](#deployment)
  - [Set up for DigitalOcean droplet](#set-up-for-digitalocean-droplet)
    - [Install Docker and Docker Compose](#install-docker-and-docker-compose)
    - [Set up deploy user](#set-up-deploy-user)
    - [Add deploy keys to repo on Github](#add-deploy-keys-to-repo-on-github)
  - [capistrano](#capistrano)
    - [* If you met `exit status 4` while building Docker image](#-if-you-met-exit-status-4-while-building-docker-image)
  - [Deploy with CircleCI](#deploy-with-circleci)
    - [circle.yml](#circleyml)
- [Manage persistent data](#manage-persistent-data)
  - [Backup and restore data](#backup-and-restore-data)
    - [Static files in `/tmp` directory](#static-files-in-tmp-directory)
    - [DB data](#db-data)
- [TIPS: Zero time deployment with CoreOS and vulcand](#tips-zero-time-deployment-with-coreos-and-vulcand)
  - [Setup environment as Vagrant](#setup-environment-as-vagrant)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Summary

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
* Data container
  * data-only-container for persistent data like temporary file and data for DB
  * This is mounted to containers

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

For development environment, you can use `docker-compose-development.yml` on your local machine.

It is bassically same as `docker-compose.yml` for staging or production environment but it shares your local Rails project with web container with using same image as staging/production.
When you update code, you can see changes for it as you run `rails server` on your local too.

This is `docker-compose-development.yml`:

```yml
web:
  build: .
  links:
    - postgres
    - redis
  ports:
    - "80:80"
  # Following is development configuration
  command: /bin/bash -c "rake db:migrate && rails server -b 0.0.0.0 -p 80"
  environment:
    RAILS_ENV: development
  volumes_from:
    - data
# ...
# omitted some lines...
# ...
data:
  image: busybox
  volumes:
    - /tmp
    # For postgres
    - /var/lib/postgresql/data
    - .:/usr/src/app
```

## Deployment

**Currently, this examples does not support hot-deployment. This example has deployment task by capistrano but it needs to restart all containers when you want to update applciation.**

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
  * This task excutes 3 command of `docker-compose`: stop, rm and up. You don't have to care of containers running as it stops all of runnning containers.

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


## Manage persistent data

This project uses data-only-container for portability of persistent data, for example, temporary file which is needed by the application, DB data and etc.
It follows the instruction in Documentation of Docker: [Managing data in containers - Docker Documentation](https://docs.docker.com/userguide/dockervolumes/) and There's nothing new to the documentation.

This project has Resque job, `FileCreator`. This is just to create file when the new post was created. And file is saved in `/tmp` in production; this is sample so it is meaningless!. See  `config/settings/production.yml` and `app/jobs/file_creator.rb`.

Following is the way to backup files which was saved in `/tmp` and restore them.

### Backup and restore data

#### Static files in `/tmp` directory

In this case, it just needs to create backup file from container directory and extract it to container.

```sh
# Create backup as a tar file
docker run --volumes-from railsdockerexample_data_1 -v $(pwd)/backup:/backup busybox tar cvf /backup/backup.tar /tmp
# Restore it
docker run --volumes-from railsdockerexample_data_1 -v $(pwd)/backup:/backup busybox tar xvf /backup/backup.tar
```

#### DB data

If you need to backup and restore postgres DB data, you can do it by following:

```sh
# Create backup as a tar file
docker run --volumes-from railsdockerexample_data_1 -v $(pwd)/backup:/backup busybox tar cvf /backup/backup.tar /var/lib/postgresql/data
# Restore it
docker run --volumes-from railsdockerexample_data_1 -v $(pwd)/backup:/backup busybox tar xvf /backup/backup.tar
# Restart containers; As restarted container may have new ip address and Rails knows it only to read ENV --- it was set --link option and it will not update automatically
docker-compose restart
```

#### Using cron to create backup

backup script `provisioning/backup-data-container.sh` is added to `/etc/cron.hourly/backup-data-container.sh`. Below is the script for backup data.

```sh
#!/bin/sh -x

echo "Start to create backup for DB..."
docker run --volumes-from railsdockerexample_data_1 -v /backup/db:/backup busybox tar cvf /backup/db_$(date +%Y%m%d%H%M).tar /var/lib/postgresql/data

echo "Start to create backup for /tmp ..."
docker run --volumes-from railsdockerexample_data_1 -v /backup/tmp:/backup busybox tar cvf /backup/tmp_$(date +%Y%m%d%H%M).tar /tmp
```

## TIPS: Zero time deployment with CoreOS and vulcand

We can do zero time deployment by using CoreOS and [mailgun/vulcand](https://github.com/mailgun/vulcand). This project has `Vagrantfile` to up the environment for it.

Ref: [Vulcand を使って Docker コンテナをブルーグリーンデプロイする - Qiita](http://qiita.com/spesnova/items/34d787f6b46761f775a4#upstream-example-v1-%E3%81%AE%E8%A8%AD%E5%AE%9A)

Quite simple to do that. vulcand has the very simple system to handle some endpoints; `Frontend`, `Backend` and `Servers`. In this case, the container is `Server`.

We can build and start container with versioned source code with commit-id then switch endpoint like this:

```sh
# Create new Backend linked to new version
etcdctl set /vulcand/backends/8c5a86/backend '{"Type": "http"}'

# Create new Server linked to the Backend
etcdctl set /vulcand/backends/8c5a86/servers/srv1 '{"URL": "http://localhost:5000"}'

# Update Frontend with new Backend Id
etcdctl set /vulcand/frontends/f1/frontend '{"Type": "http", "BackendId": "8c5a86", "Route": "PathRegexp(`/.*`)"}'
```

```
┌───────────────────────────────────────────────────────────────────┐
│                             FrontEnd                              │
│              {"Type": "http", "BackendId": "a43bd2",              │
│                   "Route": "PathRegexp(`/.*`)"}                   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                                  │
Frontend forwards request to      │  * Switch the target "Server" by set
the container which was linked    │  backend Id of commit id via etcd
to backend                        │  API after the new container was
                ┌─────────────────┘  built and ready.
                │
                │
                │
                │
                ▼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│            Backend            │   │            Backend            │
│   /vulcand/backends/a43bd2    │   │   /vulcand/backends/8c5a86    │
│       {"Type": "http"}        │   │       {"Type": "http"}        │
│                               │   │                               │
└───────────────────────────────┘   └───────────────────────────────┘
                ┼                                   ┼
                │                                   │
                ┼                                   ┼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│            Server             │   │            Server             │
│/vulcand/backends/a43bd2/server│   │/vulcand/backends/8c5a86/server│
│            s/srv1             │   │            s/srv1             │
│{"URL": "http://0.0.0.0:8080"} │   │{"URL": "http://0.0.0.0:8081"} │
└───────────────────────────────┘   └───────────────────────────────┘
                ┼                                   ┼
                │                                   │
                ┼                                   ┼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│       Docker container        │   │       Docker container        │
│       (built as a43bd2)       │   │       (built as 8c5a86)       │
│         0.0.0.0:8080          │   │         0.0.0.0:8081          │
│                               │   │                               │
└───────────────────────────────┘   └───────────────────────────────┘
```

**NOTICE: This wouldn't fit production environment as it builds Docker image inside the only host. It may affects performance while users send request to the only host. For production, it needs to change to use Docker registry and run containers by pulling image from there.**

### Setup environment as Vagrant

Install vagrant dns plugin for local dns. Then run `vagrant up` to up your local environment.

**This plugin supports MacOS only**

```sh
vagrant plugin install vagrant-dns
vagrant dns --install
vagrant ssh-config >> ~/.ssh/config
vagrant up
# After vagrant is ready, deploy with capistrano task
bundle exec cap local docker:deploy # `local` environment is for vagrant
# The default address of Vagrant environment is http://172.17.8.101/
```

### See how it works to deploy it to Vagrant

All needed tasks are already included in [lib/capistrano/tasks/docker.rake](https://github.com/mookjp/rails-docker-example/blob/master/lib%2Fcapistrano%2Ftasks%2Fdocker.rake).
Before testing zero-time-deployment, fix `:repo_url`; URL of repository in [config/deploy/local.rb#L12](https://github.com/mookjp/rails-docker-example/blob/master/config%2Fdeploy%2Flocal.rb#L12).

You can deploy new containers with zero time deployment with Vagrant:

```sh
# Edit your code
git add your/change
git commit
git push your-remote master
bundle exec cap local docker:deploy # `local` environment is for vagrant
```

As I mentioned above, `docker:deploy` will do:

1. Build new image if code was updated
2. Run new container
3. Add new `Backend` and `Server` for new container
4. Wait container is ready
5. Switch `Frontend` configuration to forward to new container
6. Remove old container


## TIPS: Remove Docker images when disk space is low

If you want to remove Docker images as disk space is low, you can use capistrano tasks to do that.

There're 2 tasks for that:

```
cap docker:remove_all_images       # Remove all containers then remove all images
cap docker:remove_useless_images   # Remove images which is not tagged
```

## Problems and TODOs

### For production
