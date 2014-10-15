#
#   Author: Rohith
#   Date: 2014-10-11 17:04:22 +0100 (Sat, 11 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistrar
  module Backends
    class Etcd < Backend
      require 'etcd'

      def set path, value, ttl = 0
        begin
          etcd.set path, value, recursive: true, ttl: ttl
        rescue Exception => e
          raise BackendFailure, e.message
        end
      end

      private
      def self.valid? configuration
        return false unless configuration['host']
        return false unless configuration['port']
        true
      end

      def etcd
        @etcd ||= connection
      end

      def connection
        info "connection: attempting to make a connection to etcd backend service:"
        ::Etcd::Client.connect( uris: config['uri'] )
      end
    end
  end
end
