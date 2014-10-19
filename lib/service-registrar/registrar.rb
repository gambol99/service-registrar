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
          sleep_ms interval
          measure_time 'processing.ms' do
            available_services = []
            # step: generate the services
            container_documents do |path,document|
              available_services << path
              debug "run: path: #{path}, ttl: #{service_time_to_live}, document: #{document}"
              # step: push the document into the backend
              measure_time 'services.set.ms' do
                backend.set path, document.to_json, service_time_to_live
              end
            end
            host_services_document available_services do |document|
              # step: push the hosts / services /host/[HOSTNAME]/services
              measure_time 'hosts.set.ms' do
                debug "run: host path: #{backed_host_services_path}, services: #{document}"
                backend.set backed_host_services_path, document.to_json
              end
            end
            # step: are we pruning the services?
            if pruning?
              # step: get a current list of services we are running
              advertised_services = backend.paths(backend_services_prefix).select do |path,host|
                host == hostname
              end
              # step: deduct what we have from what we have advertised
              bad_services = advertised_services.keys - available_services
              # step: do we have any services that should't be there?
              if !bad_services.empty?
                bad_services.each do |bad_service_path|
                  info "run: deleting the bad service: #{bad_service_path}"
                  backend.delete bad_service_path
                end
              end
            end
            debug "run: going to sleep for #{interval}ms"
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
  end
end
