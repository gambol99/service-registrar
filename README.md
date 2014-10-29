Service-Registrar
=================

Services
-----------------

By default service documents are placed under the path

    /[ENV:ENVIRONMENT]/[ENV:APP]/[ENV:NAME]/[SERVICE:PORT]

Containers are broken up into service ports, creating a definition per port i.e

    [jest@starfury bin]$ docker ps | grep etcd
50ccf6e665e0        coreos/etcd:latest       "/opt/etcd/bin/etcd    46 hours ago        Up 46 hours         0.0.0.0:49155->4001/tcp, 0.0.0.0:49156->7001/tcp                                                                                                                                                                                           jovial_albattani

Would create definitions;

    {
        :id=>"50ccf6e665e09b0d60445725bfa1993e0e185cc9b8c85af745fcace624f8ecf0",
        :host=>"mesos-master",
        :ipaddress=>"10.0.1.100",
        :env=>{"APP"=>"etcd", "NAME"=>"etc", "ENVIRONMENT"=>"prod", "HOME"=>"/" },
        :tags=>[],
        :name=>"/jovial_albattani",
        :image=>"coreos/etcd",
        :docker_hostname=>"50ccf6e665e0",
        :host_port=>"49156",
        :proto=>"tcp",
        :port=>"7001", :
        path=>"/services/prod/etc/etcd/7001"
    }

    {
        :id=>"50ccf6e665e09b0d60445725bfa1993e0e185cc9b8c85af745fcace624f8ecf0",
        :host=>"mesos-master",
        :ipaddress=>"10.0.1.100",
        :env=>{"APP"=>"etcd", "NAME"=>"etc", "ENVIRONMENT"=>"prod", "HOME"=>"/" },
        :tags=>[],
        :name=>"/jovial_albattani",
        :image=>"coreos/etcd",
        :docker_hostname=>"50ccf6e665e0",
        :host_port=>"49155",
        :proto=>"tcp",
        :port=>"4001",
        :path=>"/services/prod/etc/etcd/4001"
    }

Under etcd keys of:

    /services/prod/etc/etcd/4001
    /services/prod/etc/etcd/7001

Note; you can override the service port with a more readable name by injecting the environmental variable

    SERVICE_<PORT>_NAME=""

    i.e.

    -e SERVICE_4001_NAME="etcd_clients"
    -e SERVICE_7001_NAME="etcd_peers"
    =
    /services/prod/etc/etcd/etcd_clients
    /services/prod/etc/etcd/etcd_peers

Prune vs TTL
-----------------

Service documents are expired either by TTLs or via pruing. By default the TTL of a document is 12 seconds, with each interval resetting the document ttl. Personally, I never liked the idea; if your using it to build out some load balancer etc; a registration process failure could timeout the documents/service and end up with a empty load balance config. Pruning is the other option, service document do not have a TTL, on every iteration, the advertised services in the registry is compared to what we JUST found and if there's anything which shouldn't be there, it's removed - the trade off bring I'd rather have old config than no config.

Configuration
-----------------

    The configuration can be loaded from a yaml file with the -c <FILE> command line options; the defaults for the services are given below

    def default_configuration
      {
        'docker'          => env('DOCKER_SOCKET','/var/run/docker.sock'),
        'interval'        => env('INTERVAL','3000').to_i,
        'ttl'             => env('TTL','12000').to_i,
        'log'             => env('LOGFILE',STDOUT),
        # The logging level
        'loglevel'        => env('LOGLEVEL','info'),
        # The hostname to use when registering services, should be the docker host
        'hostname'        => env('HOST', %x(hostname -f).chomp ),
        # The ip address to use when advertising the service - namely the ip address of the docker host
        'ipaddress'       => env('IPADDRESS', get_host_ipaddress ),
        # The prefix to use when sending events/metrics to statsd
        'prefix_stats'    => env('PREFIX_STATSD','registrar-service'),
        # The prefix to use when adding the services information - directory backend only
        'prefix_services' => env('PREFIX_SERVICES','/services'),
        # The prefix to use when adding the hosts information - directory backend only
        'prefix_hosts'    => env('PREFIX_HOSTS','/hosts'),
        # This is used when adding to a directoy service, like etcd or zookeeper
        'prefix_path'     => [
          'environment:ENVIRONMENT',
          'environment:NAME',
          'environment:APP',
          'service:PORT',
        ],
        # The method to use when disposing services
        'service_ttl'     => 'prune', # ttl
        # The backend uri for registering services in
        'backend'  => env('BACKEND','etcd://localhost:4001'),
      }
    end

Backends:
---------

The backend or registry is configured using a simple uri - from the command line or from the BACKEND environment variable

    # ./registrar run -B etcd://192.168.13.90:49155 -i 3000
    or
    # ./registrar run -B consul://192.168.13.90:8500 -i 3000

Docker Build & Run
------------------

    # git clone https://github.com/gambol99/service-registrar
    # cd service-registrar
    # docker build -t service-registrar -- .
    # docker run -d -P
        -e HOST=$HOSTNAME \
        -e IPADDRESS=$PRIVATE_IP_ADDRESS \
        -e BACKEND="etcd://<IP>:<PORT>"
        -e DOCKER_SOCKET=/var/sockets/docker.socket \
        -v /var/run:/var/sockets service-registrar

Docker Testing
------------------

	# DOCKER_ID=$(docker run -d -e APP=etcd -e NAME=backend -P -e ENVIRONMENT=prod coreos/etcd)
	# ETCD_PORT=$(docker port $DOCKER_ID 4001 | cut -d':' -f2)
	# ETCD_HOST=$(hostname --ip-address)
	# IPADDRESS=$ETCD_HOST
	# HOST="test101"
	# docker run -d -P \
        -e HOST=$HOSTNAME \
        -e IPADDRESS=$IPADDRESS \
        -e BACKEND="etcd://${ETCD_HOST}:${ETCD_PORT}"
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
