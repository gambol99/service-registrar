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
        api_operation do
          set_options = {
            :value => value,
            :recursive => true
          }
          set_options[:ttl] = ttl if ttl > 0
          etcd.set path, set_options
        end
      end

      def delete path
        api_operation do
          etcd.delete path, recursive: true
        end
      end

      def paths root_path = default_root_path
        api_operation do
          paths_list recursive_nodes( root_path )
        end
      end

      private
      def paths_list node, list = {}
        if node.dir
          node.children.each { |x| paths_list(x,list) } if node.children
        else
          list[node.key] = JSON.parse(node.value)['host']
        end
        list
      end

      def recursive_nodes root
        api_operation do
          etcd.get( root , :recursive => true ).node
        end
      end

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
        options = {
          :host => config['host'],
          :port => config['port'],
        }
        debug "connection: host: #{config['host']}, port: #{config['port']}"
        options[:ca_file]  = config['ca_file'] if config['ca_file']
        options[:use_ssl]  = true if config['use_ssl']
        options[:ssl_cert] = OpenSSL::X509::Certificate.new( File.read( config['ssl_cert'] ) ) if config['ssl_cert']
        options[:ssl_key]  = OpenSSL::PKey::RSA.new(config['ssl_key']) if config['ssl_key']
        ::Etcd.client( options )
      end
    end
  end
end
