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

    private
    def validate_configutation config = options[:config]
      raise ArgumentError, "you have not specified any configuration file" unless config
      raise ArgumentError, "you have not specified the interval time" unless config['']
    end

    def set_default_options config
      config.merge!( default_options )
    end

    def configuration config = options[:config]
      @configuration ||= YAML.load(File.read(config))
    end
  end
end
