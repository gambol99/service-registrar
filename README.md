Service-Registrar
=================

Docker Service Registration


Services
-----------------

By default service documents are placed under the path

    /[ENV:PROD]/[ENV:NAME]/[ENV:APP]/[DOCKER_ID]

Example:

    path: /services/prod/backend/etcd/0d520d265f52, ttl: 0,
    document:
        {
            :id         => "0d520d265f5216cea9d070da511332a167bbff9c0d3d2099db6d93fe6367ea8a",
            :updated    => 1413836623,
            :host       => "mesos-slave101",
            :ipaddress  => "10.0.1.201",
            :image      => "etcd",
            :domain     => "",
            :entrypoint => ["/opt/etcd/bin/etcd"],
            :tags       => [],
            :cpushares  => 0,
            :memory     => 0,
            :volumes    => {},
            :name       => "/focused_torvalds",
            :running    => true,
            :docker_pid => 4888,
            :ports=>{
                "4001/tcp"=>[{"HostIp"=>"0.0.0.0", "HostPort"=>"49153"}],
                "7001/tcp"=>[{"HostIp"=>"0.0.0.0", "HostPort"=>"49154"}]
            }
        }

Prune vs TTL
-----------------

Service documents are expired either by TTLs or via pruing. By default the TTL of a document is 12 seconds, with each interval resetting the document ttl. Personally, I never liked the idea; if your using it to build out some load balancer etc; a registration process failure could timeout the documents/service and end up with a empty load balance config. Pruning is the other option, service document do not have a TTL, on every iteration, the advertised services in the registry is compared to what we JUST found and if there's anything which shouldn't be there, it's removed - the trade off bring I'd rather have old config than no config.

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
        -e HOST=$HOSTNAME \
        -e IPADDRESS=$PRIVATE_IP_ADDRESS \
        -e DOCKER_SOCKET=/var/sockets/docker.socket \
        -v /var/run:/var/sockets service-registrar

Docker Testing
------------------

	# DOCKER_ID=$(docker run -d -e APP=etcd -e NAME=backend -P -e ENVIRONMENT=prod etcd)
	# ETCD_PORT=$(docker port $DOCKER_ID 4001 | cut -d':' -f2)
	# ETCD_HOST=$(hostname --ip-address)
	# IPADDRESS=$ETCD_HOST
	# HOST="test101"
	# docker run -d -P \
        -e ETCD_HOST=$ETCD_HOST \
        -e ETCD_PORT=$ETCD_PORT \
        -e HOST=$HOSTNAME \
        -e IPADDRESS=$IPADDRESS \
        -e DOCKER_SOCKET=/var/sockets/docker.sock \
        -v /var/run:/var/sockets service-registrar

	# watch the keys
	# watch -d -n1 "./etcdclt --peers $IPADDRESS:$ETCD_PORT --no-sync ls --recursive"

	# create some dockers
	# docker run -d -e APP=redis -e NAME=master -P -e ENVIRONMENT=prod redis
	# docker run -d -e APP=redis -e NAME=slave -P -e ENVIRONMENT=prod redis
	# docker run -d -e APP=redis -e NAME=slave -P -e ENVIRONMENT=prod redis


Contributing
------------

 - Fork it
 - Create your feature branch (git checkout -b my-new-feature)
 - Commit your changes (git commit -am 'Add some feature')
 - Push to the branch (git push origin my-new-feature)
 - Create new Pull Request
 - If applicable, update the README.md
