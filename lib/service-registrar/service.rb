#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-17 17:56:43 +0100 (Fri, 17 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistrar
  module Service
    private
    def host_services_document services, &block
      yield backend_hosts_prefix + '/' + hostname, {
        :hostname => hostname,
        :services => services
      }
    end

    def container_documents &block
      containers do |container|
        unless running?( container )
          next unless settings['running_only']
        end
        service_document container do |path,document|
          yield path, document if block_given?
        end
      end
    end

    def service_document docker, &block
      config      = extract_docker_config docker
      info        = extract_docker_info docker
      environment = extract_docker_environment docker
      path = service_path docker, environment
      debug "service_document: generating the service path: #{path}"
      service = {
        :id          => docker.id,
        :updated     => Time.now.to_i,
        :host        => hostname,
        :ipaddress   => host_ipaddress,
        :image       => config['Image'],
        :domain      => config['Domainname'] || '',
        :entrypoint  => config['Entrypoint'] || '',
        :tags        => extract_docker_environment_tags( environment ),
        :cpushares   => config['CpuShares'],
        :memory      => config['Memory'],
        :volumes     => info['Volumes'] || {},
        :name        => info['Name'],
        :running     => info['State']['Running'],
        :docker_pid  => info['State']['Pid'] || 0,
        :ports       => info['NetworkSettings']['Ports'] || {}
      }
      yield path, service if block_given?
    end

    def running? docker
      extract_docker_info(docker)['State']['Running']
    end

    def service_path docker, environment
      # step: generate the path from the elements
      path = backend_services_path.inject([]) { |paths,x|
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
      "#{backend_services_prefix}/#{path.join('/')}"
    end

    def backend_services_path
      settings['service_path']
    end

    def backend_services_prefix
      settings['services_prefix']
    end

    def backend_hosts_prefix
      settings['hosts_prefix']
    end

    def backed_host_services_path
      "#{backend_hosts_prefix}/#{hostname}"
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
        hostname
      when 'IPADDRESS'
        host_ipaddress
      end
    end

    def hostname
      settings['hostname']
    end

    def host_ipaddress
      settings['ipaddress'] || get_host_ipaddress
    end

    def service_time_to_live
      ( settings['service_ttl'] == 'ttl' ) ? to_seconds( settings['ttl'] ) : 0
    end
  end
end
