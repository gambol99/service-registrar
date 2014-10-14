#
#   Author: Rohith
#   Date: 2014-10-10 20:53:17 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Configuration
    def default_options
      {
        'docker'      => 'unix:///var/run/docker.sock',
        'interval'    => '5000',
        'timetolive'  => '12000',
        'log'         => '/var/log/registar.log',
        'loglevel'    => 'INFO',
        'backend'     => 'zookeeper',
        'backends'    => {
          'zookeeper' => {
            'uri'   => 'zk://localhost:2181',
            'path'  => '/services',
          }
        }
      }.dup
    end

    def set_default_options config
      config.merge!( default_options )
    end

    def settings
      @settings ||= {}
    end

    def options default_options = {}
      @options ||= default_options
    end

    private
    def validate_configuration config
      # step: start by loading the configuration if we have one
      @configuration = load_configuration config['config']
      # step: merge the

      # step: start by bringing in the default options and merge user defined options
      @configuration = default_options.merge!( config )
      # step: now validate we have everything
      validate_config_file config
      # step: read in the configuration
      configuration = load_configuration config
      # step: check we have everything we need
      required_settings %(docker interval ttl log loglevel backend backends), configuration
      # step: check the actual settings
      raise ArgumentError, "interval should be a positive integer" unless postive_integer? configuration['interval']
      raise ArgumentError, "ttl should be positive integer"        unless postive_integer? configuration['ttl']
    end

    def validate_config_file config
      raise ArgumentError, "you have not specified any configuration file" unless config['config']
      # step: validate the configuration file
      validate_config_file config['config']
    end

    def validate_backend_configuration configuration
      backend = configuration['backend']
      backend_config = configuration['backends'][backend] || {}
      # check the backend exists
      unless backends.include? backend
        raise ArgumentError, "invalid backend, available backends are #{backends.join(',')}"
      end
      unless configuration['backends'].has_key? backend
        raise ArgumentError, "you have not specified any backend configuration"
      end
      # check the backend config
      unless backend_config? backend
        raise ArgumentError, "invalid backend configuration for #{backend}" unless backend_config?
      end
    end

    def load_configuration filename
      ( filename ) ? YAML.load(File.read(filename)) : {}
    end
  end
end
