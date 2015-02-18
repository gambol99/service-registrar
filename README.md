Service-Registrar
=================

Services
-----------------

By default service documents are placed under the path

    /[ENV:ENVIRONMENT]/[ENV:APP]/[ENV:NAME]/[SERVICE:PORT]/[SERVICE:HOSTPORT]/[SERVICE:HOSTNAME]

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

Service documents are expired either by TTLs or via pruning. By default the TTL of a document is 12 seconds, each interval iteration resetting the document ttl. Personally, I don't like the idea of using TTLs, if your using the service data to build out a load balancer config, the process failing/dying could timeout the documents/service and end up with a empty load balance config. Pruning is the other option, service document do not have a TTL associated, on every iteration the currently running services are collected and checked against those which are advertised in the registry. Anything which should no longer be there is removed and the rest left unaltered.

Configuration
-----------------

    The configuration can be loaded from a yaml file with the -c <FILE> command line options; the defaults for the services are given below

    def default_configuration
      {
          # the path of the docker socker
          'docker'          => env('DOCKER_SOCKET','/var/run/docker.sock'),
          # the interval between service run
          'interval'        => env('INTERVAL','3000').to_i,
          # the time in seconds for TTLs on services - used if service_ttl == 'ttl'
          'ttl'             => env('TTL','12000').to_i,
          # the place to write logs, default to stdout
          'log'             => env('LOGFILE',STDOUT),
          # The logging level
          'log_level'       => env('LOGLEVEL','info'),
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
          'prefix_path'     => %w(environment:ENVIRONMENT environment:NAME service:PORT service:HOST_PORT service:HOSTNAME),
          # The method to use when disposing services
          'service_ttl'     => 'prune', # ttl
          # The backend uri for registering services in
          'backend'  => env('BACKEND','etcd://localhost:4001'),
        }
    end

Backend's:
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
    # docker run -d -P \
        -e HOST=$HOSTNAME \
        -e IPADDRESS=$PRIVATE_IP_ADDRESS \
        -e BACKEND="etcd://<IP>:<PORT>" \
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
        -e BACKEND="etcd://${ETCD_HOST}:${ETCD_PORT}" \
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
