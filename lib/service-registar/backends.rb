#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'backend'
require 'backends/zookeeper'
require 'backends/etcd'

module ServiceRegistar
  module Backends
    def backends
      debug "backends: pulling a list of the backends"
      ServiceRegistar::Backends.constants.select { |x|
        Class === ServiceRegistar::Backends.const_get( x )
      }.delete_if { |x| x =~ /Backend/ }.map(&:downcase).map(&:to_s)
    end

    def backend? name
      debug "backend? checking the backend: #{name} exists"
      backends.include? name
    end

    def backend_configuration name, configuration
      debug "backend_configuration: validating the configuration is correct"
      ServiceRegistar::Backends.const_get( name.capitalize.to_sym ).valid? configuration
    end

    private
    def load_backend name, configuration
      debug "load_backend: name: #{name}, configuration: #{configuration}"
      raise ArgumentError, "the backend: #{name} is not supported" unless backend? name
      ServiceRegistar::Backends.const_get( name.capitalize.to_sym ).new( configuration )
    end

    class BackendFailure < StandardError; end
  end
end
