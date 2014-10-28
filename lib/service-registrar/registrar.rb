#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'docker-api'
require 'config'
require 'utils'
require 'backends'
require 'logging'
require 'service'
require 'errors'
require 'events'
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
    include ServiceRegistrar::Errors
    include ServiceRegistrar::Events

    def initialize config = {}
      load_configuration config
      # step: create the docker thread runing
      initialize_watches
    end

    def run
      begin
        wait_on_queue do |event|
          info "run: event: #{event} received"
          case event[:type]
          when Events::DOCKER_EVENT, Events::INTERVAL
            debug "starting the processing"
            available_services = {}
            measure_time 'processing.ms' do
              container_documents do |path,document|
                available_services[path] = document
                debug "process: path: #{path}, ttl: #{service_time_to_live}, document: #{document}"
                # step: push the document into the backend
                measure_time 'services.set.ms' do
                  backend.service path, document, service_time_to_live
                end
              end
            end
            if pruning?
              measure_time 'services.pruning.ms' do
                backend.pruning hostname, prefix_services, available_services
              end
            end
            # step: update the alive gauge
            gauge 'alive'
          end
        end
      rescue BackendFailure => e
        error "process: backend failure, error: #{e.message.chomp}"
        increment 'backend.failures'
      rescue SystemExit => e
        info "process: received a SystemExit exception"
        exit 1
      rescue SignalException => e
        error "process: received a SignalException exception, #{e.message}"
        exit 1
      end
    end

    private
    def initialize_watches
      info "initialize_watches: creating the timer thread"
      timer_event
      info "initialize_watches: creating the docker events thread"
      docker_event
      info "initialize_watches: creating the statistics thread"
      statistics_runner
    end

    def wait_on_queue &block
      loop do
        yield queue.pop if block_given?
      end
    end

    def timer_event
      @timer_thread ||= Thread.new do
        wake(interval) do
          debug "timer_event: about to push timer event into queue"
          queue.push type: Events::INTERVAL
        end
      end
    end

    def docker_event
      @docker_events ||= Thread.new do
        ::Docker::Events.stream do |event|
          puts "HELLO"
          case event[:status]
          when /(create|destroy)/
            debug "pushing event into the queue"
            queue.push type: Events::DOCKER_EVENT
          end
        end
        puts "ENDED"
      end
    end

    def queue
      @queue ||= Queue.new
    end

    def backend
      @backend ||= nil
      if @backend.nil?
        info "backend: backend: #{settings['backend']}, interval: #{interval}"
        # step: load the backend plugin
        debug "backend: loading the backend provider: #{settings['backend']}"
        @backend = load_backend settings['backend'], settings
        debug "backend: backend provider: #{backend.inspect}"
      end
      @backend
    end
  end
end
