#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-17 17:56:43 +0100 (Fri, 17 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'pp'

module ServiceRegistrar
  module Service
    private
    def service_documents
      containers do |container|
        # step: skip containers which are not running
        next unless running? container
        # step: split the container into it's services
        service_port_document container do |document|
          yield document[:path], document
        end
      end
    end

    def service_port_document(container)
      info = container_info(container)
      config = container_config(container)
      network = info['NetworkSettings']
      ports = network['Ports'] || {}
      service = {
          :id => container.id,
          :host => hostname,
          :ipaddress => ipaddress,
          :env => container_environment(container),
          :tags => container_tags(container),
          :name => info['Name'],
          :image => config['Image'],
          :hostname => config['Hostname'],
      }
      if ports.any?
        ports.each_pair do |port, mapping|
          port = service_port service, port, mapping
          service_definition = service.dup.merge(port)
          # step: generate the service path
          service_definition[:path] = service_path service_definition
          yield service_definition
        end
      else
        # condition: the container does not expose any service ports
        service_definition = service.dup
        service_definition[:path] = service_path service_definition
        yield service_definition
      end
    end

    def service_path(service)
      # step: generate the path from the elements
      path = prefix_path.inject([]) { |paths, x|
        # step: ignore any illigal formated
        unless x =~ /^\w+:\w+$/
          error "service_path: element: #{x} is invalid, skipping the element"
          next
        end
        elements = x.split(':')
        element_type = elements[0]
        element_value = elements[1]
        case element_type
          when 'environment'
            paths << service[:env][element_value] || 'unknown'
          when 'string'
            paths << element_value
          when 'service'
            case element_value
              when /^PORT$/
                service_name = "SERVICE_#{service[:port]}_NAME"
                paths << service[:env][service_name] if service[:env][service_name]
                paths << service[element_value.downcase.to_sym] unless service[:env][service_name]
              else
                paths << service[element_value.downcase.to_sym]
            end
        end
        paths
      }.compact
      "#{prefix_services}/#{path.join('/')}"
    end

    def service_port(service, port, mapping)
      port_definition = parser_docker_port(port)
      raise ArgumentError, 'the port definition is invalid' unless port_definition
      if mapping.nil?
        port_definition[:port] = nil
      else
        port_mapping = mapping.first
        service[:ipaddress] = port_mapping['HostIp'] unless port_mapping['HostIp'] == '0.0.0.0'
        service[:host_port] = port_mapping['HostPort']
      end
      port_definition
    end

    def parser_docker_port(port)
      return {:proto => $3, :port => $1} if port =~ /^([0-9]+)($|\/(tcp|udp))/
      warn "parser_docker_port: invalid port definition: #{port}"; nil
    end

    def running?(container)
      container_info(container)['State']['Running']
    end

    def container_info(container)
      container.info
    end

    def container_config(container)
      container_info(container)['Config']
    end

    def container_network(container)
      container_info(container)['NetworkSettings']
    end

    def container_environment(container)
      split_array(container_config(container)['Env'] || {})
    end

    def container_tags(container)
      (container_environment(container)['Tags'] || '').split(',')
    end

    def service_time_to_live
      ( settings['service_ttl'] == 'ttl' ) ? to_seconds( settings['ttl'] ) : 0
    end
  end
end
