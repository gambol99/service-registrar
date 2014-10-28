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

      def service path, document, time_to_live
        api_operation do
          # step: check if the path already exists and if not, set it
          unless etcd.exists? path
            info "service: path: #{path}, service: #{document}"
            set_options = {
              :value     => document.to_json,
              :recursive => true
            }
            set_options[:ttl] = time_to_live if time_to_live > 0
            etcd.set path, set_options
          end
        end
      end

      def pruning hostname, services_path, available_services
        # step: get a current list of services we are running
        #debug "pruning: hostname: #{hostname}, services_path: #{services_path}, available_services: #{available_services}"
        advertised_services = advertised_paths hostname, services_path
        #debug "pruning: advertised_services: #{advertised_services}"
        # step: deduct what we have from what we have advertised
        bad_services = advertised_services.keys - available_services.keys
        # step: do we have any services that should't be there?
        if !bad_services.empty?
          bad_services.each do |bad_service_path|
            info "pruning: deleting the bad service: #{bad_service_path}"
            delete bad_service_path
          end
        end
      end

      private
      def delete path
        api_operation do
          etcd.delete path, recursive: true
        end
      end

      def advertised_paths hostname, services_path = '/services'
        etcd_services_paths(services_path).select do |path,host|
          debug "path: #{path}, hostname: #{hostname}, host: #{host}"
          host == hostname
        end
      end

      def etcd_services_paths root_path = default_root_path
        api_operation do
          etcd_paths recursive_nodes( root_path )
        end
      end

      def etcd_paths node, list = {}
        if node.dir
          node.children.each { |x| etcd_paths(x,list) } if node.children
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

      def etcd
        @etcd ||= connection
      end

      def connection
        @etcd_hostname ||= uri_hostname uri
        @etcd_port     ||= uri_port uri
        debug "connection: host: #{@etcd_hostname}, port: #{@etcd_port}"
        ::Etcd.client( host: @etcd_hostname, port: @etcd_port )
      end
    end
  end
end
