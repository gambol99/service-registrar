#
#   Author: Rohith
#   Date: 2014-10-11 17:04:16 +0100 (Sat, 11 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistrar
  module Backends
    class Zookeeper < Backend
      require 'zookeeper'

      def service(path, document, ttl)
        api_operation do
          debug "service: path: #{path}, document: #{document}"
          # step: zookeeper does not support a recursive set, we need to ensure the path
          ensure_path path
          # step: set the key/value
          zoo.set path: path, data: document
        end
      end

      def pruning(hostname, services_path, available_services)

      end

      private
      def delete(path)
        api_operation do
          debug "delete: path: #{path}"
          zoo.delete path: path
        end
      end

      def ensure_path(path)
        debug "ensure_path: #{path}"
        File.dirname(path).split('/').inject([]) do |root,element|
          cursor = root.join('/')
          # step: check if the cursor path exists
          zoo.create(path: cursor) if zoo.get_children(path: cursor).nil?
          root << element
          root
        end
      end

      def zoo
        @zookeeper ||= ::Zookeeper.new(config['uri'])
      end
    end
  end
end
