#
#   Author: Rohith
#   Date: 2014-10-10 20:53:17 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'yaml'

module ServiceRegistrar
  module Configuration
    def default_configuration
      {
        'docker'          => env('DOCKER_SOCKET','/var/run/docker.sock'),
        'interval'        => env('INTERVAL','3000').to_i,
        'ttl'             => env('TTL','12000').to_i,
        'log'             => env('LOGFILE',STDOUT),
        # The logging level
        'loglevel'        => env('LOGLEVEL','info'),
        # The hostname to use when registering services, should be the docker host
        'hostname'        => env('HOST', %x(hostname -f).chomp ),
        # The ip address to use when advertising the service - namely the ip address of the docker host
        'ipaddress'       => env('IPADDRESS', get_host_ipaddress ),
        # The prefix to use when sending events/metrics to statsd
        'prefix_stats'    => env('PREFIX_STATSD','registrar-service'),
        # The prefix to use when adding the services information - directory backend only
        'prefix_services' => env('PREFIX_SERVICES','/services'),
        # The prefix to use when adding the hosts information - directory backend only
        'prefix_hosts'    => env('PREFIX_HOSTS','/hosts'),
        # This is used when adding to a directoy service, like etcd or zookeeper
        'prefix_path'     => [
          'environment:ENVIRONMENT',
          'environment:NAME',
          'service:PORT',
          'service:HOST_PORT',
          'service:HOSTNAME',
        ],
        # The method to use when disposing services
        'service_ttl'     => 'prune', # ttl
        # The backend uri for registering services in
        'backend'  => env('BACKEND','etcd://localhost:4001'),
      }
    end

    def settings
      @configuration ||= {}
    end

    def interval
      settings['interval']
    end

    def pruning?
      settings['service_ttl'] == 'prune'
    end

    def hostname
      settings['hostname']
    end

    def ipaddress
      settings['ipaddress']
    end

    def running_only?
      settings['running_only']
    end

    %w(path services hosts stats).each do |x|
      define_method "prefix_#{x}" do
        settings["prefix_#{x}"]
      end
    end

    private
    # method: loads the default configuration, merges the config file, the environment file
    # and this the user defined options to produce the final service config
    def load_configuration config
      # step: start by loading the default configuration
      @configuration = default_configuration
      # step: load the configuration file if we have one
      @configuration.merge!(load_configuration_file config['config'])
      # step: load any environment file
      @configuration.merge!(load_environment_file config['environment']) if config['environment']
      # step: merge the user defined options
      @configuration.merge!(config)
      # step: setup the logger
      Logging::Logger::init @configuration['log'], loglevel(@configuration['loglevel'])
      # checkpoint: we should have a fully merged config now
      debug "validate_configuration: merged configuration: #{@configuration}"
      # step: verfiy the config is correct
      validate_configuration @configuration
    end

    def validate_configuration configuration
      debug "validate_configuration: validating the configuration"
      # step: check we have valid service method
      raise ArgumentError, "invalid service ttl method" unless service_method? configuration['service_ttl']
      # step: check the backend configuration
      raise ArgumentError, "the backend: #{backend} does not exits" unless backend? configuration['backend']
      # step: check the docker socket
      validate_docker configuration
      # step: return the configuration
      info "configuration: #{configuration}"
      configuration
    end

    def validate_docker configuration
      %w(exists socket readable writable).each do |x|
        unless File.send("#{x}?".to_sym, configuration['docker'] )
          raise ArgumentError, "the docker socket file: #{configuration['docker']} does or is not #{x}"
        end
      end
    end

    def service_method? method
      method[/^(ttl|prune)$/]
    end

    def load_environment_file filename = '/etc/environment'
      config = {}
      info "load_environment: checking for a environment file: #{filename}"
      if File.file? filename and File.readable? filename
        parse_environment_file filename do |key,value|
          config[key] = value
          debug "adding environment var: #{key} value: #{value}"
          config[key.downcase] = value
        end
      end
      config
    end

    def parse_environment_file filename, &block
      File.open( filename ).each do |x|
        next unless x =~ /^(.*)=(.*)$/
        yield $1, $2
      end
    end

    def load_configuration_file filename
      ( filename ) ? ::YAML.load(File.read(filename)) : {}
    end
  end
end
