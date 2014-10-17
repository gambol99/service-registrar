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
    def generate_service_document docker, &block
      debug "generate_service_document: generating the service pack: docker: #{docker.id}"
      config      = extract_docker_config docker
      info        = extract_docker_info docker
      environment = extract_docker_environment docker
      path = generate_service_path docker, environment
      debug "generate_service_document: generating the service path: #{path}"
      #PP.pp info
      service = {
        :id          => docker.id,
        :updated     => Time.now.to_i,
        :host        => settings['hostname'],
        :image       => config['Image'],
        :domain      => config['Domainname'] || '',
        :entrypoint  => config['Entrypoint'] || '',
        :tags        => extract_docker_environment_tags( environment ),
        :cpushares   => config['CpuShares'],
        :memory      => config['Memory'],
        :volumes     => info['Volumes'] || {},
        #:created     => Time.new(info['Created']).to_i,
        :name        => info['Name'],
        :running     => info['State']['Running'],
        :docker_pid  => info['State']['Pid'] || 0,
        :ports       => info['NetworkSettings']['Ports'] || {}
      }
      yield path, service if block_given?
    end

    def generate_service_path docker, environment
      # step: generate the path from the elements
      path = service_path.inject([]) { |paths,x|
        # step: ignore any illigal formated
        unless x =~ /^\w+:\w+$/
          error "service_path: element: #{x} is invalid, skipping the element"
          next
        end
        elements = x.split(':')
        element_type  = elements[0]
        element_value = elements[1]
        case element_type
        when 'environment'
          paths << environment[element_value] || 'unknown'
        when 'string'
          paths << element_value
        when 'container'
          paths << extract_docker_config_item( docker, element_value )
        when 'provider'
          paths << extract_provider_info( element_value )
        end
      }.compact
      "/" << path.join('/')
    end

    def service_path
      settings['path']
    end

    def services_prefix
      settings['services_prefix']
    end

    def hosts_prefix
      settings['hosts_prefix']
    end

    def host_services_path
      "#{hosts_prefix}/#{settings['hostname']}"
    end

    def extract_docker_info docker
      docker.info
    end

    def extract_docker_environment_tags environment
      ( environment['TAGS'] || "" ).split(',')
    end

    def extract_docker_environment docker
      split_array( docker.info['Config']['Env'] || {} )
    end

    def extract_docker_config docker
      docker.info['Config']
    end

    def extract_docker_config_item docker, key
      extract_docker_config(docker)[key.downcase.capitalize]
    end

    def extract_provider_info key
      case key
      when 'HOSTNAME'
        settings['hostname']
      end
    end

    def service_time_to_live
      ( settings['service_ttl'] == 'ttl' ) ? to_seconds( settings['ttl'] ) : 0
    end
  end
end
