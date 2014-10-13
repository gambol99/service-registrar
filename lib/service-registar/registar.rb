#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'backends'
require 'docker-api'
require 'thread'

module ServiceRegistar
  class Registar
    include ServiceRegistar::Utils
    include ServiceRegistar::Logging
    include ServiceRegistar::Config
    include ServiceRegistar::Backends
    include ServiceRegistar::Docker
    include ServiceRsgistar::Statistics

    def initialize config = {}
      # step: save the configuration in options
      options config
      # step: load the configuration file
      validate_configuration options[:config]
      # step: initialize the backend and load the plugin
      initialize_backend options
      # step: initialize the web interface
      initialize_webui options
    end

    private
    def run
      loop do



      end
    end




    def options default_options
      @options ||= default_options.dup
    end
  end
end
