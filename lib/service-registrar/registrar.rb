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
require 'service'
require 'statistics'

module ServiceRegistrar
  class Registrar
    include ServiceRegistrar::Logging
    include ServiceRegistrar::Utils
    include ServiceRegistrar::Configuration
    include ServiceRegistrar::Backends
    include ServiceRegistrar::DockerAPI
    include ServiceRegistrar::Statistics
    include ServiceRegistrar::Service

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
      # step: run the statistics dumper
      statistics_runner
      loop do
        begin
          sleep_ms settings['interval']
          measure_time 'processing.ms' do
            debug "run: starting a event run"
            host_services = {
              :ipaddress => settings['hostname'],
              :services  => []
            }
            # step: generate the services
            containers do |container|
              generate_service_document container do |path,document|
                host_services[:services] << path
                debug "path: #{path}, document: #{document}"
                # step: push the document into the backend
                measure_time 'services.set.ms' do
                  backend.set path, document.to_json, service_time_to_live
                end
              end
            end
            # step: push the hosts / services /host/[HOSTNAME]/services
            measure_time 'hosts.set.ms' do
              debug "host path: #{host_services_path}, services: #{host_services}"
              backend.set host_services_path, host_services.to_json
            end
            debug "run: going to sleep for #{settings['interval']}ms"
            gauge 'alive'
          end
        rescue BackendFailure => e
          error "run: backend failure, error: #{e.message.chomp}"
          increment 'backend.failures'
        rescue SystemExit => e
          info "run: received a SystemExit exception"
          exit 1
        rescue SignalException => e
          error "run: received a SignalException exception, #{e.message}"
          exit 1
        end
      end
    end

    private
    def pruning?
      settings['service_ttl'] == 'prune'
    end
  end
end
