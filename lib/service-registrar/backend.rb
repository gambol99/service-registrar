#
#   Author: Rohith
#   Date: 2014-10-13 20:45:39 +0100 (Mon, 13 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'logging'
require 'errors'

module ServiceRegistrar
  class Backend
    include ServiceRegistrar::Logging
    include ServiceRegistrar::Errors

    attr_reader :config
    def initialize config
      @config = config
    end

    def self.valid? configuration
      raise ArgumentError, "valid? the backend method has not been overloaded"
    end

    protected
    def api_operation &block
      begin
        yield
      rescue Exception => e
        error "api_operation: #{e.message}"
        raise BackendFailure, e.message
      end
    end

    def default_root_path
      '/services'
    end
  end
end
