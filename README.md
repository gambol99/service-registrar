Service-Registrar
=================

Docker Service Registration

Configuration
-----------------
    
    The configuration can be loaded from a yaml file with the -c <FILE> command line options; the defaults for the services are given below
    
    def default_configuration
      {
        # the file location of the docker socket
        'docker'          => env('DOCKER_SOCKET','/var/run/docker.sock'),
        # the interval between updates to the registry (zookeeper/etcd/consul)
        'interval'        => env('INTERVAL','5000').to_i,
        # the default time to live when using service_ttl == 'ttl'
        'ttl'             => env('TTL','12000').to_i,
        # fairly obvious
        'log'             => env('LOGFILE',STDOUT),
        'loglevel'        => env('LOGLEVEL','info'),
        # Allow use to override the hostname, useful when running inside of a docker
        'hostname'        => env('HOSTNAME', %x(hostname -f).chomp ),
        # The ip address to advertise in the service document
        'ipaddress'       => env('IPADDRESS',get_host_ipaddress),
        'stats_prefix'    => env('STATS_PREFIX','registrar-service'),
        # the path prefixes to the registry
        'services_prefix' => '/services',
        'hosts_prefix'    => '/hosts',
        # Only push service document for RUNNING containers?
        'running_only'    => true,
        'service_ttl'     => 'prune', # ttl
        # Allows use to customize the markup of the service path push into the registry
        'path'     => [
          "environment:ENVIRONMENT",
          "environment:NAME",
          "environment:APP",
          "container:HOSTNAME",
        ],
        'backend'  => env('BACKEND','etcd'),
        'backends' => {
          'zookeeper' => {
            'uri'   => env('ZOOKEEPER_URI','localhost:2181'),
          },
          'etcd' => {
            'host'  => env('ETCD_HOST','localhost'),
            'port'  => env('ETCD_PORT','4001').to_i
          }
        }
      }
    end

Docker Build & Run
------------------
    
    # git clone https://github.com/gambol99/service-registrar
    # cd service-registrar
    # docker build -t service-registrar -- .
    # docker run -d -P 
        -e ETCD_HOST=<IP> \
        -e ETCD_PORT=<PORT> \ 
        -e HOSTNAME=$HOSTNAME \
        -e IPADDRESS=$PRIVATE_IP_ADDRESS \
        -e DOCKER_SOCKET=/var/sockets/docker.socket \
        -v /var/run:/var/sockets service-registrar


Contributing
------------

 - Fork it Create your feature branch (git checkout -b my-new-feature)
 - Commit your changes (git commit -am 'Add some feature') 
 - Push to the branch (git push origin my-new-feature) 
 - Create new Pull Request 
 - If applicable, update the README.md
