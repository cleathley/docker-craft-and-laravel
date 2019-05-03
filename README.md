## Docker Environment for use with Craft or Laravel Projects

```** This documentation is work in progress and may not be complete. I will be addeding more documentation on how things work next week.```

### Introduction

This repository contains both a docker file which will build a 
docker image based on Ubuntu 16.04 with Nginx, Php 7.1 and Redis 
aswell as a docker compose environment which will build a more 
complex multi frontend behind a load balancer setup. 

This project has some very specific needs for our company with the 
requirement of the php ```MS SQL``` drivers as well as ssh keys for access 
to our private bit bucket accounts. Both of these steps can be removed 
from the Dockerfile is you are using this as a basis for `Dockerising` 
your own development / production environments.

My hope is to provide a simple example of how to set up docker for 
development with both a simple script to run which will build up a 
Docker container to allow for local development as well as using 
docker-compose to build up a multi server application sitting behind 
a load balancer and using redis as a caching environment for session handling

Docker is cross platform but any examples given are based on Docker for 
Windows and using git bash as the CLI

### Docker File

The Docker image created by the docker file does things a bit differently 
as it runs several services within the same image.  This was purposely 
done to keep it simple as we have to deal with staff with different skill 
sets and we want to keep things simple as developers only have to learn 
a few commands.  

Docker only allows for a single process to be run from within a container 
so we use 'supervisor' to launch Nginx, Php and Redis

The default web root is ```/public``` which suits Craft 2 and Laravel Projects.  
If you are wanting Craft 3 support you will have to change the ```nginx.default.conf``` 
file so the nginx root uses ```/web``` instead. 

The docker file will basically create a Ubuntu web server running php7.1 
with a self signed SSL.

We generally use a dedicated SQL server which the developers use as a shared 
resource.  The docker file does not create any SQL services other 
than adding the mysql command line tools to the image. 

You will need to have a basic understand how docker works with management of 
```images``` and ````containers```` but the shell script included should do 
all the heavy work for you.

```redis``` is installed by default. It's upto you if you want to use it.  It can be accessed on ```localhost``` if requried.    

### Installation
  
You will need to install 

gitbash ([https://git-scm.com/downloads](https://git-scm.com/downloads))

> This provides a nice CLI for git as well as allowing for linux type shell 
scripts to run under windows. If you are natively running under Mac os or Linux 
then you can ignore this step.

and

Docker for Windows ([https://hub.docker.com](https://hub.docker.com))

> You are best to sign up and create an account. There is no cost with this nor 
do you have to provide anything more than your name and email address..

> If you are using Mac Os or Linux then you will need to install the version 
for your OS.  

You can install composer if you wish but it is installed in the docker image 
and it's just as easy to ssh into the machine the run if from there. 
(composer under windows can be a bit of a pain to setup)

To get the docker environment up and running you will have to copy all the 
files in this repo into the main folder of your Craft/Laravel (or any other 
php based project) (you can exclude the README.md :)

```
    .docker/
    Dockerfile
    docker-compose.yml
```

If your project requires any access to any private repos (ie. company) you will 
need to copy your .ssh folder over to the project. (make sure to add .ssh
to your ```.gitignore``` file). If you don't require this than remove the SSH 
key section from the ```Dockerfile```


At that point you will only have to run the ```run.sh``` command from git bash 
(once you have ```cd```'d into your project folder). 

This will build the docker image (the first time you do this It 
can take approximately 15-20 minutes as it has to do a full install of 
a linux server. Once the image has been created it will only take a 
few seconds to start on subsequent runs)

The docker instance will mount the current folder (on your local environment) 
into ```/web``` within the Docker container.

Running the Docker image in this mode will output all the HTTP traffic logs 
and any php errors to the console.

At this point you can use your local web browser and go the either for the 
following urls

[http://localhost:81](http://localhost:81) or [https://localhost](https://localhost)

> If going the ```HTTPS``` route (which you should) you will need to accept the 
browser warning of the self signed SSL certificate.

The running container is called ```slave```.  You can SSH into it using.

```winpty docker exec -it slave bash```

You will have to do this in a new gitbash window as the window used the run 
the container will be outputting the logs.
 
 > If you are using Mac Os or Linux you won't need to use the initial winpty 
 (as this is only require under a Windows environment)

Pressing ```Control ^C``` will exit the running Docker container and stop it 
(this may take a second or so).

### Docker Compose

The shell ```run.sh``` command will spool up a single container running 
your application. If you require something a little more advanced then 
`docker compose` can be used to spool up a ```Nginx``` load balancer, ```2 front``` 
end web servers and a ```redis``` server to handle session management.

> We are not going to tell you how to configure your site to use ```redis``` as this 
is easily documented in whatever cms/framework you are using. 

You can use ```docker-compose up``` to spool up this environment.

The environment variable ```REDIS_URL``` (passed into your container) can be used to configure your site 
to use the redis server. 
