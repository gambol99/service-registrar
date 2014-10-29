#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-23 12:02:37 +0100 (Thu, 23 Oct 2014)
#
#  vim:ts=2:sw=2:et
#

# Environment Varibles
#
#   CONSUL_DC                   : the consul datacenter
#   SERVICE_<PORT>_NAME         : the service name associated to the port
#   SERVICE_<PORT>_META_NAME    : Attributes associated to the service
#   SERVICE_<PORT>_TAG
#   SERVICE_TAGS
#
module ServiceRegistrar
  module Backends
    class Consul < Backend
      require 'httparty'
      module ConsulAPI
        def api_version
          @consul_version ||= "/v1"
        end

        def api_catalog
          @consul_api_version ||= api_version + "/catalog"
        end

        def api_catalog_register
          @consul_api_catalog_register ||= api_catalog + "/register"
        end

        def api_catalog_deregister
          @consul_api_catalog_deregister ||= api_catalog + "/deregister"
        end

        def api_node_services
          @node_services ||= api_catalog + '/node'
        end
      end
      include ConsulAPI

      def service path, document, ttl
        advertised_services = list_services(document[:host])
        # step: convert the document into a consul service
        consul_services document do |service|
          # step: is the service already advertised?
          if advertised_services.empty? or !advertised_services["Services"].has_key?( service["Service"]["ID"] )
            info "service: consul service: #{service}"
            register_service service
          end
        end
      end

      def pruning hostname, services_path, available_services
        # step: get a list of advertised services we apparently have
        advertised = list_services( hostname )
        # step: if we have not services - we can throw back
        return if advertised.empty?
        # step: strip out the services
        advertised_services = advertised["Services"]
        # step: we need to convert to consul services and grab the ids
        available_consul_services = {}
        available_services.each_pair do |path,document|
          consul_services document do |service|
            service_id = service["Service"]["ID"]
            available_consul_services[service_id] = service
          end
        end
        # step: look for services that shouldnt be here and unregister them
        bad_services = advertised_services.keys - available_consul_services.keys
        # step: delete anything that shouldn't be there
        unless bad_services.empty?
          bad_services.each do |id|
            info "pruning: service id: #{id} should not be advertised"
            service_removal = {
              'Node'       => advertised['Node']['Node'],
              'Address'    => advertised['Node']['Address'],
              'Datacenter' => 'dc1',
              'ServiceID'  => id
            }
            deregister_service service_removal
          end
        end
      end

      private
      # method: Converts the service document into one or more consul services
      def consul_services document, &block
        yield consul_service_document document
      end

      def list_services node
        service_list = api(api_node_services + "/#{node}", nil, :get)
        return {} if service_list.body =~ /^null/
        JSON.parse( service_list.body )
      end

      def register_service service
        api api_catalog_register, service
      end

      def deregister_service service
        api api_catalog_deregister, service
      end

      def consul_datacenter document
        document[:env]["CONSUL_DC"] || 'dc1'
      end

      def consul_service_name document
        port         = document[:port] || 0
        service_name = document[:env]["SERVICE_#{port}_NAME"]
        service_name ||= document[:env]["SERVICE_NAME"]
        service_name = document[:image].split('/').last + "-#{port}" if service_name.nil?
        service_name
      end

      def consul_service_document document
        {
          "Datacenter" => consul_datacenter(document),
          "Node"       => document[:host],
          "Address"    => document[:ipaddress],
          "Service"    => {
            "Port"    => document[:port].to_i,
            "Service" => consul_service_name(document),
            "Tags"    => document[:tags],
            "ID"      => document[:path],
          }
        }
      end

      def api uri, payload, method = :post
        api_operation do
          url  = consul_hostname + uri
          data = payload.to_json if payload
          debug "url: #{url}, method: #{method}"
          response = HTTParty.send method, url, :body => data
          unless response.code == 200
            raise Exception, "api: payload: #{payload}, response: #{response.code}, message: #{response.body}"
          end
          response
        end
      end

      def consul_hostname
        @consul_hostname ||= "http://#{uri_hostname(uri)}:#{uri_port(uri)}"
      end
    end
  end
end
