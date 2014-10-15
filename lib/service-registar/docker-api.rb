#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
gem 'docker-api', :require => 'docker'
require 'docker'

module ServiceRegistar
  module DockerAPI
    def containers &block
      raise ArgumentError, 'you have not specified a block' unless block_given?
      ::Docker::Container.all.each do |docker|
        yield ::Docker::Container.get( docker.id )
      end
    end

    def docker_environment docker
      split_array( docker.info['Config']['Env'] || {} )
    end

    def docker_config docker
      docker.info['Config']
    end
  end
end
