#
#   Author: Rohith
#   Date: 2014-10-10 20:53:17 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Configuration
    class << self
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
        }
      end

      def settings[key]
        @settings[key]
      end
    end

    def options default_options = {}
      @options ||= default_options
    end

    private
    def validate_configuration config
      raise ArgumentError, "you have not specified any configuration file" unless config
      # step: validate the configuration file
      validate_config_file config
      # step: read in the configuration and validate
      configuration = load_configuration config
      # step: check we have everything we need
      required_settings %(docker interval ttl log loglevel backend backends), configuration
      # step: check the actual settings
      raise ArgumentError, "interval should be a positive integer" unless postive_integer? configuration['interval']
      raise ArgumentError, "ttl should be positive integer"        unless postive_integer? configuration['ttl']

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

    def postive_integer? value
      ( !value.is_a? Integer or value <= 0 ) ? false : true
    end

    def required_settings list, supplied
      list.each do |x|
        raise ArgumentError, "you have not specified the #{x} options" unless supplied.has_key? x
      end
    end

    def set_default_options config
      config.merge!( default_options )
    end

    def load_configuration config, options = {}
      # step: read in the configuration
      config_data ||= YAML.load(File.read(config)) || {}
      # step: merge in the suer defined options
      config_data.merge( options )
    end

    def validate_config_file filename
      raise ArgumentError, "the configuration: #{filename} does not exists" unless File.exists? filename
      raise ArgumentError, "the configuration: #{filename} is not a file"   unless File.file? filename
      raise ArgumentError, "the configuration: #{filename} is not readable" unless File.readable? filename
    end
  end
end
