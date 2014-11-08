#
#   Author: Rohith
#   Date: 2014-10-10 20:53:36 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'backend'
require 'backends/zookeeper'
require 'backends/etcd'
require 'backends/consul'

module ServiceRegistrar
  module Backends
    def backend?(uri)
      uri[/^(consul|etcd|zoo):\/\//] ? true : false
    end

    private
    def load_backend(uri, config)
      case uri
        when /^zoo:/
          instance_backend('zookeeper', uri, config)
        when /^etcd:/
          instance_backend('etcd', uri, config)
        when /^consul:/
          instance_backend('consul', uri, config)
        else
          raise ArgumentError, "the backend: #{url} is not supported"
      end
    end

    def instance_backend(name, uri, settings)
      klassName = name.capitalize.to_sym
      debug "instance_backend: attempting to load the backend, class: #{klassName}"
      ServiceRegistrar::Backends.const_get(klassName).new(uri, settings)
    end
  end
end
