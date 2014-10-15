#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'thread'
require 'docker-api'
require 'config'
require 'utils'
require 'backends'
require 'logging'
require 'pp'

module ServiceRegistar
  class Registar
    include ServiceRegistar::Utils
    include ServiceRegistar::Configuration
    include ServiceRegistar::Logging
    include ServiceRegistar::Backends
    include ServiceRegistar::DockerAPI

    def initialize config = {}
      info "initialize: setting up the registar service"
      # step: load and validate the configuration
      info "initialize: validating the service configuration"
      validate_configuration config
      info "initialize: service registar successfully initialized"
    end

    def run
      info "run: backend: #{settings['backend']}, interval: #{settings['interval']}"

    end

    private
  end
end
