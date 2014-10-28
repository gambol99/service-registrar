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
    include ServiceRegistrar::Utils

    attr_reader :config, :uri

    def initialize uri, config
      @uri    = uri
      @config = config
    end

    protected
    def api_operation &block
      begin
        yield
      rescue Exception => e
        error "api_operation: #{e.message}"
        raise Errors::BackendFailure, e.message
      end
    end

    def service hostname, services_path, available_services
      raise Exception, "backend: the service method has not been defined"
    end

    def pruning available_service, service_path
      raise Exception, "backend: the pruning method has not been defined"
    end

    def default_root_path
      '/services'
    end
  end
end
