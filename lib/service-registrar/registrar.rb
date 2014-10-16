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
require 'statistics'

module ServiceRegistrar
  class Registrar
    include ServiceRegistrar::Logging
    include ServiceRegistrar::Utils
    include ServiceRegistrar::Configuration
    include ServiceRegistrar::Backends
    include ServiceRegistrar::DockerAPI
    include ServiceRegistrar::Statistics

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
            containers do |container|
              # step: extract the path from the container
              path = service_path container
              # step: extract the required information from container
              service = service_information container
              debug "path: #{path}, service: #{service}"
              # step: push the service into the backend
              measure_time 'backend.ms' do
                backend.set path, service.to_json, to_seconds( settings['ttl'] )
              end
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
    def service_information docker
      config    = docker.info
      service = {
        :id         => docker.id,
        :updated    => Time.now.to_i,
        :host       => hostname,
        :ipaddress  => advertised,
        :image      => config['Image'],
        :domain     => config['Domainname'] || '',
        :entrypoint => config['Entrypoint'] || '',
        :volumes    => config['Volumes'] || {},
        :running    => config['State']['Running'],
        :docker_pid => config['State']['Pid'] || 0,
        :ports      => config['NetworkSettings']['Ports'] || {}
      }
      service
    end

    def service_path docker
      # step: get the path elements
      path_elements = settings['path']
      # step: get the docker environment variables
      environment   = docker_environment docker
      # step: the docker information
      docker_info   = docker_config docker
      # step: generate the path from the elements
      path = path_elements.inject([]) { |paths,x|
        value = nil
        # step: ignore any illigal formated
        unless x =~ /^\w+:\w+$/
          error "service_path: element: #{x} is invalid, skipping the element"
          next
        end
        elements = x.split(':')
        element_type  = elements[0]
        element_value = elements[1]
        case element_type
        when 'environment'
          paths << environment[element_value] || 'unknown'
        when 'string'
          paths << element_value
        when 'container'
          paths << docker_info[element_value.downcase.capitalize]
        end
      }.compact
      "/" << path.join('/')
    end

    def hostname
      @hostname ||= %x(hostname -f).chomp
    end

    def advertised
      @advertised ||= settings['advertised']
    end
  end
end
