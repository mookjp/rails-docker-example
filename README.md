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

## How to run

### Requirements

These are required to run it as Docker containers.

* docker
* docker-compose

### Run containers

All you have to do is bellow:

```sh
docker-compose up
```
