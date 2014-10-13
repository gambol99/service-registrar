#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'backends/backend'
require 'backends/zookeeper'
require 'backends/etcd'

module ServiceRegistar
  module Backends
    def backends
      ServiceRegistar::Backends.constants.select { |x|
        Class === ServiceRegistar::Backends.const_get( x )
      }.delete_if { |x| x =~ /Backends/ }
    end

    def backend? name
      backends.include? name.to_sym
    end

    private
    def load_backend name, configuration
      debug "backend: name: #{name}, configuration: #{configuration}"
      raise ArgumentError, "the backend: #{name} is not supported" unless backend? name
      ServiceRegistar::Backends.const_get( name.to_sym ).new( configuration )
    end
  end
end
