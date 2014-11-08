#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
gem 'docker-api', :require => 'docker'
require 'docker'

module ServiceRegistrar
  module DockerAPI
    def containers
      # step: ensure the docker socket
      set_docker_socket
      ::Docker::Container.all.each do |docker|
        yield ::Docker::Container.get(docker.id)
      end
    end

    def set_docker_socket
      @socket ||= nil
      unless @socket
        @socket = "unix://#{settings['docker']}"
        info "set_docker_socket: setting the docker socket: #{@socket}"
        ::Docker.url = @socket
        info 'set_docker_socket: socket set'
      end
    end
  end
end
