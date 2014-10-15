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
    include ServiceRegistar::Logging
    include ServiceRegistar::Utils
    include ServiceRegistar::Configuration
    include ServiceRegistar::Backends
    include ServiceRegistar::DockerAPI

    def initialize config = {}
      # step: load the configuration
      validate_configuration config
      info "initialize: service registar successfully initialized"
    end

    def run
      info "run: backend: #{settings['backend']}, interval: #{settings['interval']}"
      # step: load the backend plugin
      debug "run: loading the backend provider: #{settings['backend']}"
      backend_cfg = settings['backends'][settings['backend']]
      backend = load_backend settings['backend'], backend_cfg
      debug "run: backend provider: #{backend.inspect}"
      loop do
        # step:
        begin
          debug "run: starting a event run"
          containers do |container|
            # step: extract the path from the container


            # step: extract the required information from container

            # step: push the service into the backend

            # step: update any statistics

          end
          debug "run: going to sleep for #{settings['interval']}ms"
          sleep_ms settings['interval']
        rescue SystemExit => e
          error "run: received a SystemExit exception"
        rescue SignalException => e
          error "run: received a SignalException exception, #{e.message}"
          exit 1
        end
      end
    end
  end
end
