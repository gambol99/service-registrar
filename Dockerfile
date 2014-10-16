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
RUN sudo apt-get install -y patch make supervisor
RUN sudo gem install -V docker docker-api etcd zookeeper optionscrapper
ADD lib /opt/registrar/lib
ADD bin /opt/registrar/bin
ADD docker/config/config.yml /opt/registrar/config.yml
ADD docker/config/registar.conf /etc/supervisor/conf.d/registrar.conf
ENV APP registrar
ENV ENVIRONMENT prod
ENV NAME registrar-service
VOLUME /var/run/docker.sock:/var/run/docker.sock
CMD [ "/usr/bin/supervisord", "-n" ]
