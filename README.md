# expressionengine-docker
A simple script to setup an ExpressionEngine site with Docker and Docker Compose. I wrote and tested this on my MacBook.... 

## Pre-requisites
* Docker 
* Docker Compose 
* Mysql client

## Usage
* clone repo
* To setup the inital project from terminal run: 
    * `./init.sh`
* To download the database: 
    * `./data/dbdump.sh `
* To inport the downloaded database on startup
    * `./data/startup.sh `

## IMPORTANT
Because we are using docker to communicate between containers you must use the MySQL Host name output at the end of the script to configure ExpressionEngine. 

## Goodies to clean up during testing
* Clean up containers
    * `docker rm -f $(docker container ls -qa)`
* Clean up files
    * `rm -rf downloads/ data/ public/ system/ build/docker-compose.yml`