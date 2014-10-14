#
#   Author: Rohith
#   Date: 2014-10-11 17:04:16 +0100 (Sat, 11 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Backends
    class Zookeeper < Backend
      require 'zookeeper'

      def set path, value, ttl = nil
        # step: include the ttl in the object
        value[:ttl] = ttl
        # step: we need to make sure the path exists
        ensure_pathway path
        # step: set the value
        zookeeper.set path: path, data: value
      end

      private

      def self.valid? configuration
        return false unless configuration['uri']
        true
      end

      def ensure_pathway path
        root = ''
        zookeeper_path = path.gsub(/^\/+/,'')
        zookeeper_path.split('/').each do |x|
          root << "/#{x}"
          children = zookeeper.get_children( path: root )
          zookeeper.create path: root if children[:children].nil?
        end
      end

      def zookeeper
        @zookeeper ||= nil
        @zookeeper = connection if @zookeeper.nil? or !@zookeeper.connected?
      end

      def connection
        Zookeeper.new config['uri']
      end
    end
  end
end
