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
          if !advertised_services["Services"].has_key?(service["Service"]["ID"])
            info "service: consul service: #{service}"
            register_service service
          end
        end
      end

      def pruning hostname, services_path, available_services
        # step: get a list of advertised services we apparently have
        advertised = list_services( hostname )
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
        service_ports document[:host], document[:ports] do |service_port|
          yield consul_service_document(service_port,document)
        end
      end

      def service_ports node_address, ports, &block
        ports.each_pair do |port,mapping|
          if port =~ /^([0-9]+)($|\/(tcp|udp))/
            service_map  = mapping.first
            service_port = {
              :host_port       => service_map['HostPort'].to_i,
              :container_port  => $1.to_i,
              :proto           => $3 || 'tcp'
            }
            service_port[:host_ip] = case service_map['HostIp']
            when /^(0\.){3}0$/; node_address
            else
              service_map['HostIp']
            end
            yield service_port
          end
        end
      end

      def list_services node
        JSON.parse( api(api_node_services + "/#{node}", nil, :get).body )
      end

      def register_service service
        api api_catalog_register, service
      end

      def deregister_service service
        api api_catalog_deregister, service
      end

      def consul_service_name document, port
        service_name   = document[:environment]["SERVICE_#{port}_NAME"]
        service_name ||= document[:environment]["SERVICE_NAME"]
        service_name = document[:image].split('/').last + "-#{port}" if service_name.nil?
        service_name
      end

      def consul_service_tags document, port
        service_tags = nil
        if document[:environment]["SERVICE_#{port}_TAGS"]
          service_tags = document[:environment]["SERVICE_#{port}_TAGS"].split(',')
        elsif document[:environment]["SERVICE_TAGS"]
          service_tags = document[:environment]["SERVICE_TAGS"].split(',')
        end
        service_tags ||= []
      end

      def consul_datacenter document
        document[:environment]["CONSUL_DC"] || 'dc1'
      end

      def consul_service_document service_port, document
        container_port = service_port[:container_port]
        host_name      = document[:host]
        host_port      = service_port[:host_port]
        host_ip        = service_port[:host_ip]
        datacenter     = consul_datacenter(document)
        service = {
          "Datacenter" => datacenter,
          "Node"       => host_name,
          "Address"    => host_ip,
          "Service"    => {}
        }
        service_name = consul_service_name(document,container_port)
        service_tags = consul_service_tags(document,container_port)
        service_id   = "%s/%s/%d" % [host_name,service_name,host_port]
        service["Service"] = {
          "Port"    => host_port,
          "Service" => service_name,
          "Tags"    => service_tags,
          "ID"      => service_id
        }
        service
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
