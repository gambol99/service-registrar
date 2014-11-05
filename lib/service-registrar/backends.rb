require 'backend'
require 'backends/zookeeper'
require 'backends/etcd'
require 'backends/consul'

module ServiceRegistrar
  module Backends
    private
    def backend
      @backend ||= nil
      unless @backend
        info "backend: backend: #{settings['backend']}, interval: #{interval}"
        @backend = load_backend settings['backend'], settings
      end
      @backend
    end

    def backend?(uri)
      ( uri =~ /^(etcd|consul):\/\// ) ? true : false
    end

    def load_backend(uri, config)
      raise StandardError, "the backend: #{url} is not presently supported" unless backend? uri
      case uri
        when /^zoo/
          instance_backend('zookeeper', uri, config)
        when /^etcd/
          instance_backend('etcd', uri, config)
        when /^consul/
          instance_backend('consul', uri, config)
      end
    end

    def instance_backend(name, uri, settings)
      klassName = name.capitalize.to_sym
      debug "instance_backend: attempting to load the backend, class: #{klassName}"
      ServiceRegistrar::Backends.const_get(klassName).new(uri, settings)
    end
  end
end
