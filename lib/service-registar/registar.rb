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

module ServiceRegistar
  class Registar
    include ServiceRegistar::Utils
    include ServiceRegistar::Configuration
    include ServiceRegistar::Logging
    include ServiceRegistar::Backends
    include ServiceRegistar::Docker

    def initialize config = {}
      # step: load and validate the configuration
      validate_configuration config
    end

    private
    def run
      loop do



      end
    end
  end
end
