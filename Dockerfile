#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
FROM ubuntu
MAINTAINER <gambol99@gmail.com>

RUN sudo apt-get update
RUN sudo apt-get install -y ruby1.9.3
RUN sudo gem install -V docker service-registar

VOLUME [ '/var/run/docker.sock:/var/run/docker.sock' ]
EXPOSE 9191
