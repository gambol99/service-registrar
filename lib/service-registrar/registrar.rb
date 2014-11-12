#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'docker-api'
require 'misc/config'
require 'misc/utils'
require 'misc/errors'
require 'misc/logging'
require 'service'
require 'statistics'
require 'backends'

module ServiceRegistrar
  class Registrar
    include ServiceRegistrar::Logging
    include ServiceRegistrar::Utils
    include ServiceRegistrar::Backends
    include ServiceRegistrar::Configuration
    include ServiceRegistrar::DockerAPI
    include ServiceRegistrar::Statistics
    include ServiceRegistrar::Service
    include ServiceRegistrar::Errors

    def initialize(config = {})
      load_configuration config
    end

    def run
      statistics_runner
      # step: wake me up on every interval
      wake(interval) do
        begin
          measure_time 'processing.ms' do
            available_services = {}
            # step: generate the services
            service_documents do |path,document|
              available_services[path] = document
              debug "run: path: #{path}, document: #{document}"
              # step: push the document into the backend
              measure_time 'services.set.ms' do
                backend.service path, document, service_time_to_live
              end
            end
            # step: are we pruning the services
            if pruning?
              measure_time 'services.pruning.ms' do
                backend.pruning hostname, prefix_services, available_services
              end
            end
            # step: update the alive gauge
            gauge 'alive'
          end
        rescue BackendFailure => e
          error "run: backend failure, error: #{e.message.chomp}"
          increment 'backend.failures'
        rescue SystemExit => e
          info 'run: received a SystemExit exception'
          exit 1
        rescue SignalException => e
          error "run: received a SignalException exception, #{e.message}"
          exit 1
        end
      end
    end
  end
end
